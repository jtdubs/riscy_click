#!/usr/bin/python3
import os
import sys
import json

def main(*args):
    with open("../riscy_click.sim/board_sim/behav/xsim/log.json", "r") as l:
        events = json.load(l)

    in_flight = []
    retired = []

    for e in events:
        if not "time" in e: break
        if e["time"] == "0": continue
        if e["pc"] == str(0xFFFFFFFF): continue

        if e["stage"] == "IF" and e["valid"] == "1":
            print("ISSUE: {0}".format(e["pc"]))
            in_flight.append({ "issue_time": e["time"], "pc": e["pc"], "ir": e["ir"] })

        if not in_flight: continue

        if e["stage"] == "ID" and "jmp_valid" in e and e["jmp_valid"] == "1":
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "jmp_time": e["time"], "jmp_addr": e["jmp_addr"] })

        if e["stage"] == "ID" and "ready" in e and (e["ready"] == "0" or e["valid"] == "1"):
            print("STALL: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "stall_start_time": e["time"] })

        if e["stage"] == "ID" and "ready" in e and e["ready"] == "1" and e["valid"] == "1":
            print("RESUME: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "stall_end_time": e["time"] })

        if e["stage"] == "ID" and "ir" in e:
            print("DECODE: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "decode_time": e["time"] })

        if e["stage"] == "EX" and "ir" in e:
            print("EXECUTE: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "execute_time": e["time"], "alu_result": e["ma_addr"] })

        if e["stage"] == "MA" and "ma_mode" in e and e["ma_mode"] == "1":
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "load_addr": e["dmem_addr"] })

        if e["stage"] == "MA" and "ma_mode" in e and e["ma_mode"] == "2":
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "store_addr": e["dmem_addr"], "store_data": e["dmem_write_data"], "store_mask": e["dmem_write_mask"] })

        if e["stage"] == "MA" and "ir" in e:
            print("MEMORY: {0}".format(e["pc"]))
            next(f for f in in_flight if f["pc"] == e["pc"]).update({ "memory_time": e["time"] })

        if e["stage"] == "WB" and "ir" in e:
            print("RETIRE: {0}".format(e["pc"]))
            instr = next(f for f in in_flight if f["pc"] == e["pc"])
            instr.update({ "writeback_time": e["time"], "writeback_addr": e["wb_addr"], "writeback_data": e["wb_data"] })
            in_flight.remove(instr)
            retired.append(instr)

    for e in retired:
        print(e)

    print(len(retired))

if __name__ == "__main__":
    main(sys.argv)
