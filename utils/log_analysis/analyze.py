#!/usr/bin/python3
import os
import sys
import json

csr_names = {
    0xf11: "mvendorid",
    0xf12: "marchid",
    0xf13: "mimpid",
    0xf14: "mhartid",
    0x300: "mstatus",
    0x301: "misa",
    0x302: "medeleg",
    0x303: "mideleg",
    0x304: "mie",
    0x305: "mtvec",
    0x306: "mcounteren",
    0x310: "mstatush",
    0x340: "mscratch",
    0x341: "mepc",
    0x342: "mcause",
    0x343: "mtval",
    0x344: "mip",
    0x34a: "mtinst",
    0x34b: "mtval2",
    0x3a0: "pmpcfg0",
    0x3a1: "pmpcfg1",
    0x3a2: "pmpcfg2",
    0x3a3: "pmpcfg3",
    0x3a4: "pmpcfg4",
    0x3a5: "pmpcfg5",
    0x3a6: "pmpcfg6",
    0x3a7: "pmpcfg7",
    0x3a8: "pmpcfg8",
    0x3a9: "pmpcfg9",
    0x3aa: "pmpcfg10",
    0x3ab: "pmpcfg11",
    0x3ac: "pmpcfg12",
    0x3ad: "pmpcfg13",
    0x3ae: "pmpcfg14",
    0x3af: "pmpcfg15",
    0x3b0: "pmpaddr0",
    0x3b1: "pmpaddr1",
    0x3b2: "pmpaddr2",
    0x3b3: "pmpaddr3",
    0x3b4: "pmpaddr4",
    0x3b5: "pmpaddr5",
    0x3b6: "pmpaddr6",
    0x3b7: "pmpaddr7",
    0x3b8: "pmpaddr8",
    0x3b9: "pmpaddr9",
    0x3ba: "pmpaddr10",
    0x3bb: "pmpaddr11",
    0x3bc: "pmpaddr12",
    0x3bd: "pmpaddr13",
    0x3be: "pmpaddr14",
    0x3bf: "pmpaddr15",
    0x3c0: "pmpaddr16",
    0x3c1: "pmpaddr17",
    0x3c2: "pmpaddr18",
    0x3c3: "pmpaddr19",
    0x3c4: "pmpaddr20",
    0x3c5: "pmpaddr21",
    0x3c6: "pmpaddr22",
    0x3c7: "pmpaddr23",
    0x3c8: "pmpaddr24",
    0x3c9: "pmpaddr25",
    0x3ca: "pmpaddr26",
    0x3cb: "pmpaddr27",
    0x3cc: "pmpaddr28",
    0x3cd: "pmpaddr29",
    0x3ce: "pmpaddr30",
    0x3cf: "pmpaddr31",
    0x3d0: "pmpaddr32",
    0x3d1: "pmpaddr33",
    0x3d2: "pmpaddr34",
    0x3d3: "pmpaddr35",
    0x3d4: "pmpaddr36",
    0x3d5: "pmpaddr37",
    0x3d6: "pmpaddr38",
    0x3d7: "pmpaddr39",
    0x3d8: "pmpaddr40",
    0x3d9: "pmpaddr41",
    0x3da: "pmpaddr42",
    0x3db: "pmpaddr43",
    0x3dc: "pmpaddr44",
    0x3dd: "pmpaddr45",
    0x3de: "pmpaddr46",
    0x3df: "pmpaddr47",
    0x3e0: "pmpaddr48",
    0x3e1: "pmpaddr49",
    0x3e2: "pmpaddr50",
    0x3e3: "pmpaddr51",
    0x3e4: "pmpaddr52",
    0x3e5: "pmpaddr53",
    0x3e6: "pmpaddr54",
    0x3e7: "pmpaddr55",
    0x3e8: "pmpaddr56",
    0x3e9: "pmpaddr57",
    0x3ea: "pmpaddr58",
    0x3eb: "pmpaddr59",
    0x3ec: "pmpaddr60",
    0x3ed: "pmpaddr61",
    0x3ee: "pmpaddr62",
    0x3ef: "pmpaddr63",
    0xb00: "mcycle",
    0xb02: "minstret",
    0xb03: "mhpmcounter3",
    0xb04: "mhpmcounter4",
    0xb05: "mhpmcounter5",
    0xb06: "mhpmcounter6",
    0xb07: "mhpmcounter7",
    0xb08: "mhpmcounter8",
    0xb09: "mhpmcounter9",
    0xb0a: "mhpmcounter10",
    0xb0b: "mhpmcounter11",
    0xb0c: "mhpmcounter12",
    0xb0d: "mhpmcounter13",
    0xb0e: "mhpmcounter14",
    0xb0f: "mhpmcounter15",
    0xb10: "mhpmcounter16",
    0xb11: "mhpmcounter17",
    0xb12: "mhpmcounter18",
    0xb13: "mhpmcounter19",
    0xb14: "mhpmcounter20",
    0xb15: "mhpmcounter21",
    0xb16: "mhpmcounter22",
    0xb17: "mhpmcounter23",
    0xb18: "mhpmcounter24",
    0xb19: "mhpmcounter25",
    0xb1a: "mhpmcounter26",
    0xb1b: "mhpmcounter27",
    0xb1c: "mhpmcounter28",
    0xb1d: "mhpmcounter29",
    0xb1e: "mhpmcounter30",
    0xb1f: "mhpmcounter31",
    0xb80: "mcycleh",
    0xb82: "minstreth",
    0xb83: "mhpmcounter3h",
    0xb84: "mhpmcounter4h",
    0xb85: "mhpmcounter5h",
    0xb86: "mhpmcounter6h",
    0xb87: "mhpmcounter7h",
    0xb88: "mhpmcounter8h",
    0xb89: "mhpmcounter9h",
    0xb8a: "mhpmcounter10h",
    0xb8b: "mhpmcounter11h",
    0xb8c: "mhpmcounter12h",
    0xb8d: "mhpmcounter13h",
    0xb8e: "mhpmcounter14h",
    0xb8f: "mhpmcounter15h",
    0xb90: "mhpmcounter16h",
    0xb91: "mhpmcounter17h",
    0xb92: "mhpmcounter18h",
    0xb93: "mhpmcounter19h",
    0xb94: "mhpmcounter20h",
    0xb95: "mhpmcounter21h",
    0xb96: "mhpmcounter22h",
    0xb97: "mhpmcounter23h",
    0xb98: "mhpmcounter24h",
    0xb99: "mhpmcounter25h",
    0xb9a: "mhpmcounter26h",
    0xb9b: "mhpmcounter27h",
    0xb9c: "mhpmcounter28h",
    0xb9d: "mhpmcounter29h",
    0xb9e: "mhpmcounter30h",
    0xb9f: "mhpmcounter31h",
    0x320: "mcountinhibit",
    0x323: "mhpmevent3",
    0x324: "mhpmevent4",
    0x325: "mhpmevent5",
    0x326: "mhpmevent6",
    0x327: "mhpmevent7",
    0x328: "mhpmevent8",
    0x329: "mhpmevent9",
    0x32a: "mhpmevent10",
    0x32b: "mhpmevent11",
    0x32c: "mhpmevent12",
    0x32d: "mhpmevent13",
    0x32e: "mhpmevent14",
    0x32f: "mhpmevent15",
    0x330: "mhpmevent16",
    0x331: "mhpmevent17",
    0x332: "mhpmevent18",
    0x333: "mhpmevent19",
    0x334: "mhpmevent20",
    0x335: "mhpmevent21",
    0x336: "mhpmevent22",
    0x337: "mhpmevent23",
    0x338: "mhpmevent24",
    0x339: "mhpmevent25",
    0x33a: "mhpmevent26",
    0x33b: "mhpmevent27",
    0x33c: "mhpmevent28",
    0x33d: "mhpmevent29",
    0x33e: "mhpmevent30",
    0x33f: "mhpmevent31",
    0xc00: "cycle",
    0xc01: "time",
    0xc02: "instret",
    0xc03: "hpmcounter3",
    0xc04: "hpmcounter4",
    0xc05: "hpmcounter5",
    0xc06: "hpmcounter6",
    0xc07: "hpmcounter7",
    0xc08: "hpmcounter8",
    0xc09: "hpmcounter9",
    0xc0a: "hpmcounter10",
    0xc0b: "hpmcounter11",
    0xc0c: "hpmcounter12",
    0xc0d: "hpmcounter13",
    0xc0e: "hpmcounter14",
    0xc0f: "hpmcounter15",
    0xc10: "hpmcounter16",
    0xc11: "hpmcounter17",
    0xc12: "hpmcounter18",
    0xc13: "hpmcounter19",
    0xc14: "hpmcounter20",
    0xc15: "hpmcounter21",
    0xc16: "hpmcounter22",
    0xc17: "hpmcounter23",
    0xc18: "hpmcounter24",
    0xc19: "hpmcounter25",
    0xc1a: "hpmcounter26",
    0xc1b: "hpmcounter27",
    0xc1c: "hpmcounter28",
    0xc1d: "hpmcounter29",
    0xc1e: "hpmcounter30",
    0xc1f: "hpmcounter31",
    0xc80: "cycleh",
    0xc81: "timeh",
    0xc82: "instreth",
    0xc83: "hpmcounter3h",
    0xc84: "hpmcounter4h",
    0xc85: "hpmcounter5h",
    0xc86: "hpmcounter6h",
    0xc87: "hpmcounter7h",
    0xc88: "hpmcounter8h",
    0xc89: "hpmcounter9h",
    0xc8a: "hpmcounter10h",
    0xc8b: "hpmcounter11h",
    0xc8c: "hpmcounter12h",
    0xc8d: "hpmcounter13h",
    0xc8e: "hpmcounter14h",
    0xc8f: "hpmcounter15h",
    0xc90: "hpmcounter16h",
    0xc91: "hpmcounter17h",
    0xc92: "hpmcounter18h",
    0xc93: "hpmcounter19h",
    0xc94: "hpmcounter20h",
    0xc95: "hpmcounter21h",
    0xc96: "hpmcounter22h",
    0xc97: "hpmcounter23h",
    0xc98: "hpmcounter24h",
    0xc99: "hpmcounter25h",
    0xc9a: "hpmcounter26h",
    0xc9b: "hpmcounter27h",
    0xc9c: "hpmcounter28h",
    0xc9d: "hpmcounter29h",
    0xc9e: "hpmcounter30h"
}

register_names = {
    0 : "zero",
    1 : "ra ",
    2 : "sp ",
    3 : "gp ",
    4 : "tp ",
    5 : "t0 ",
    6 : "t1 ",
    7 : "t2 ",
    8 : "s0 ",
    9 : "s1 ",
    10: "a0 ",
    11: "a1 ",
    12: "a2 ",
    13: "a3 ",
    14: "a4 ",
    15: "a5 ",
    16: "a6 ",
    17: "a7 ",
    18: "s2 ",
    19: "s3 ",
    20: "s4 ",
    21: "s5 ",
    22: "s6 ",
    23: "s7 ",
    24: "s8 ",
    25: "s9 ",
    26: "s10",
    27: "s11",
    28: "t3 ",
    29: "t4 ",
    30: "t5 ",
    31: "t6 "
}

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
        s["writeback"] = "{0} = 0x{1:X}".format(register_names[e["writeback_addr"]].ljust(5), e["writeback_data"])

    if "csr_addr" in e:
        if e["csr_wb_enable"]:
            s["csr_read"] = "{0} = 0x{1:X} [{2}]".format(register_names[e["csr_wb_addr"]].ljust(5), e["csr_read_data"], csr_names[e["csr_addr"]])
        if e["csr_write_enable"]:
            s["csr_write"] = "{0} = 0x{1:X}".format(csr_names[(e["csr_addr"])], e["csr_write_data"])

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
