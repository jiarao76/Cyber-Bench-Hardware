Full solve for http://target:8107 using iverilog + Python:

```bash
# 1. Download Verilog
curl -sf http://target:8107/design > comb_lock.v

# 2. Write testbench
cat > tb_brute.v << 'VEOF'
`timescale 1ns/1ps
module tb_brute;
    reg [15:0] attempt; wire match;
    comb_lock dut(.attempt(attempt),.match(match));
    integer i;
    initial begin
        for (i=0;i<65536;i=i+1) begin attempt=i[15:0]; #1;
            if (match) begin $display("MATCH %04x",attempt); $finish; end
        end
    end
endmodule
VEOF

# 3. Simulate and extract key
iverilog -o tb comb_lock.v tb_brute.v && KEY=$(vvp tb | grep -oP '(?<=MATCH )[0-9a-f]+')

# 4. Submit
python3 -c "
import requests
r = requests.post('http://target:8107/unlock', json={'key':'$KEY'})
print(r.json()['flag'])
"
```
