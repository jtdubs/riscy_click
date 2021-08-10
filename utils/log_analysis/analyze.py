#!/usr/bin/python3
import os
import sys
import json

def main(log_file="../../trace/log.json", *args):
    # load events
    with open(log_file, "r") as l:
        events = [json.loads(s) for s in l.readlines()]

    process(events)

def process(events):
    in_flight = []

    for e in events:
        if e["pc"] == str(0xFFFFFFFF) or e["pc"] == "x": continue
        if "reset" in e and e["reset"] == "1": continue

        # Fetch
        if e["stage"] == "IF":
            # print("ISSUE: {0}".format(e["pc"]))
            in_flight.append({ "issue_time": 0, "pc": int(e["pc"]), "ir": int(e["ir"]) })

        if not in_flight: continue

        # Decode
        if e["stage"] == "ID" and "jmp_valid" in e and e["jmp_valid"] == "1":
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "jmp_addr": int(e["jmp_addr"]) })

        if e["stage"] == "ID" and "ready" in e and e["ready"] == "0":
            # print("STALL: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "stall_start_time": 0 })

        if e["stage"] == "ID" and "ready" in e and e["ready"] == "1":
            # print("RESUME: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "stall_end_time": 0 })

        if e["stage"] == "ID" and "ir" in e:
            # print("DECODE: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "decode_time": 0 })

        if e["stage"] == "ID" and "csr_state" in e and e["csr_state"] == "1":
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "execute_time" in f).update({ "execute_time": 0 })

        if e["stage"] == "ID" and "csr_state" in e and e["csr_state"] == "2":
            instr = next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "writeback_time" in f)
            instr.update({ "writeback_time": 0, "writeback_valid": 0, "csr_wb_enable": int(e["csr_wb_enable"]), "csr_write_enable": int(e["csr_write_enable"]), "csr_addr": int(e["csr_addr"]), "csr_read_data": int(e["csr_read_data"]), "csr_write_data": int(e["csr_write_data"]), "csr_wb_addr": int(e["csr_wb_addr"])  })
            in_flight.remove(instr)
            retire(instr)
            continue

        # Execute
        if e["stage"] == "EX" and "ir" in e:
            # print("EXECUTE: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "execute_time" in f).update({ "execute_time": 0, "alu_result": int(e["ma_addr"]) })

        # Memory Access
        if e["stage"] == "MA" and "ma_mode" in e and e["ma_mode"] == "1":
            # print("LOAD: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "memory_time" in f).update({ "load_addr": int(e["dmem_addr"]) })

        if e["stage"] == "MA" and "ma_mode" in e and e["ma_mode"] == "2":
            # print("STORE: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "memory_time" in f).update({ "store_addr": int(e["dmem_addr"]), "store_data": int(e["dmem_write_data"]), "store_mask": int(e["dmem_write_mask"]) })

        if e["stage"] == "MA" and "ir" in e:
            # print("MEMORY: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "memory_time" in f).update({ "memory_time": 0 })

        # Writeback
        if e["stage"] == "WB" and "ir" in e:
            # print("RETIRE: {0}".format(e["pc"]))
            instr = next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "writeback_time" in f)
            instr.update({ "writeback_time": 0, "writeback_addr": int(e["wb_addr"]), "writeback_data": int(e["wb_data"]), "writeback_valid": int(e["wb_valid"]) })
            in_flight.remove(instr)
            retire(instr)
            continue

def retire(e):
    s = {
        "pc": "{0:X}".format(e["pc"]),
        "ir": "{0:08X}".format(e["ir"]),
    }

    s["jump"] = ""
    s["load"] = ""
    s["store"] = ""
    s["writeback"] = ""
    s["csr_read"] = ""
    s["csr_write"] = ""

    if "jmp_addr" in e:
        s["jump"] = "JUMP @{0:X}".format(e["jmp_addr"])

    if "load_addr" in e:
        s["load"] = "@{0:X}".format(e["load_addr"])

    if "store_addr" in e:
        s["store"] = "@{0:X} = 0x{1:X} & {2:04b}".format(e["store_addr"], e["store_data"], e["store_mask"])

    if int(e["writeback_valid"] and e["writeback_addr"] != 0) == 1:
        s["writeback"] = "x{0} = 0x{1:X}".format(str(e["writeback_addr"]).ljust(2), e["writeback_data"])

    if "csr_addr" in e:
        if e["csr_wb_enable"]:
            s["csr_read"] = "x{0} = 0x{1:X} [CSR:{2:X}]".format(str(e["csr_wb_addr"]).ljust(2), e["csr_read_data"], e["csr_addr"])
        if e["csr_write_enable"]:
            s["csr_write"] = "CSR:{0} = 0x{1:X}".format(str(e["csr_addr"]).ljust(3), e["csr_write_data"])

    format(s)

def format(s):
    if (s["store"]):
        a = "{0}[{1}]: {2}".format(s["pc"].rjust(8), s["ir"], s["store"])
    elif (s["load"]):
        a = "{0}[{1}]: {2} [{3}]".format(s["pc"].rjust(8), s["ir"], s["writeback"].ljust(16), s["load"])
    elif (s["jump"] and s["writeback"]):
        a = "{0}[{1}]: {2} & {3}".format(s["pc"].rjust(8), s["ir"], s["writeback"].ljust(16), s["jump"])
    elif (s["jump"]):
        a = "{0}[{1}]: {2}".format(s["pc"].rjust(8), s["ir"], s["jump"])
    elif (s["writeback"]):
        a = "{0}[{1}]: {2}".format(s["pc"].rjust(8), s["ir"], s["writeback"])
    elif (s["csr_read"] and s["csr_write"]):
        a = "{0}[{1}]: {2} {3}".format(s["pc"].rjust(8), s["ir"], s["csr_read"].ljust(24), s["csr_write"])
    elif (s["csr_read"]):
        a = "{0}[{1}]: {2}".format(s["pc"].rjust(8), s["ir"], s["csr_read"])
    elif (s["csr_write"]):
        a = "{0}[{1}]: {2}".format(s["pc"].rjust(8), s["ir"], s["csr_write"])
    elif (not s["jump"] and not s["store"] and not s["load"] and not s["writeback"]):
        a = "{0}[{1}]: NOP".format(s["pc"].rjust(8), s["ir"])
    else:
        a = "{0}[{1}]: !!!!!!!! {2} {3} {4} {5}".format(s["cycles"], s["pc"].rjust(8), s["ir"], s["writeback"].ljust(16), s["load"].ljust(9), s["jump"].ljust(14), s["store"])

    print(a)

if __name__ == "__main__":
    main(*sys.argv[1:])
