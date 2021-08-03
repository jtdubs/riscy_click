#!/usr/bin/python3
import os
import sys
import json

def main(*args):
    # load events
    with open("../riscy_click.sim/board_sim/behav/xsim/log.json", "r") as l:
        events = json.load(l)

    # pass #1: consolidation of stage events into single per-instruction event
    in_flight = []
    retired = []

    for e in events:
        if not "time" in e: break
        if e["time"] == "0": continue
        if e["pc"] == str(0xFFFFFFFF): continue

        # Fetch
        if e["stage"] == "IF" and e["valid"] == "1":
            # print("ISSUE: {0}".format(e["pc"]))
            in_flight.append({ "issue_time": int(e["time"]), "pc": int(e["pc"]), "ir": int(e["ir"]) })

        if not in_flight: continue

        # Decode
        if e["stage"] == "ID" and "jmp_valid" in e and e["jmp_valid"] == "1":
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "jmp_time": int(e["time"]), "jmp_addr": int(e["jmp_addr"]) })

        if e["stage"] == "ID" and "ready" in e and (e["ready"] == "0" or e["valid"] == "1"):
            # print("STALL: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "stall_start_time": int(e["time"]) })

        if e["stage"] == "ID" and "ready" in e and e["ready"] == "1" and e["valid"] == "1":
            # print("RESUME: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "stall_end_time": int(e["time"]) })

        if e["stage"] == "ID" and "ir" in e:
            # print("DECODE: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "decode_time" in f).update({ "decode_time": int(e["time"]) })

        # Execute
        if e["stage"] == "EX" and "ir" in e:
            # print("EXECUTE: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "execute_time" in f).update({ "execute_time": int(e["time"]), "alu_result": int(e["ma_addr"]) })

        # Memory Access
        if e["stage"] == "MA" and "ma_mode" in e and e["ma_mode"] == "1":
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "memory_time" in f).update({ "load_addr": int(e["dmem_addr"]) })

        if e["stage"] == "MA" and "ma_mode" in e and e["ma_mode"] == "2":
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "memory_time" in f).update({ "store_addr": int(e["dmem_addr"]), "store_data": int(e["dmem_write_data"]), "store_mask": int(e["dmem_write_mask"]) })

        if e["stage"] == "MA" and "ir" in e:
            # print("MEMORY: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "memory_time" in f).update({ "memory_time": int(e["time"]) })

        # Writeback
        if e["stage"] == "WB" and "ir" in e:
            # print("RETIRE: {0}".format(e["pc"]))
            instr = next(f for f in in_flight if f["pc"] == int(e["pc"]) and not "writeback_time" in f)
            instr.update({ "writeback_time": int(e["time"]), "writeback_addr": int(e["wb_addr"]), "writeback_data": int(e["wb_data"]) })
            in_flight.remove(instr)
            retired.append(instr)

    # pass #2: instruction summaries
    summary = []

    for e in retired:
        s = {
            "pc": "{0:X}".format(e["pc"]),
            "ir": "{0:08X}".format(e["ir"]),
            "cycles": ((e["writeback_time"]-e["issue_time"])/20000)+1,
        }

        if "jmp_addr" in e:
            s["jump"] = "JMP@{0:X}".format(e["jmp_addr"])
        else:
            s["jump"] = ""

        if "load_addr" in e:
            s["load"] = "@{0:X}".format(e["load_addr"])
        else:
            s["load"] = ""

        if "store_addr" in e:
            s["store"] = "@{0:X} = 0x{1:X} & {2:04b}".format(e["store_addr"], e["store_data"], e["store_mask"])
        else:
            s["store"] = ""

        if int(e["writeback_addr"]) != 0:
            s["writeback"] = "x{0} = 0x{1:X}".format(str(e["writeback_addr"]).ljust(2), e["writeback_data"])
        else:
            s["writeback"] = ""

        summary.append(s)

    for s in summary:
        a = "{0}[{1}]: {2} {3} {4} {5}".format(s["pc"].rjust(8), s["ir"], s["writeback"].ljust(16), s["load"].ljust(9), s["jump"].ljust(14), s["store"].ljust(34))
        print(a)

if __name__ == "__main__":
    main(sys.argv)
