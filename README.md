## Signal Naming Convention
- clk_i        - Clock (if only one used by module)
- [id]_clk_i   - Clock (if multiple used by module)
- reset_i      - Synchronous reset
- [id]_reset_i - Synchronous reset (for specified clock domain)
- *_i          - Input port
- *_o          - Registered output port
- *_async_o    - Unregistered output port (varies during clock cycle based on input)
- *_r          - Registers
- *_w          - Wires / Combinational Logic
