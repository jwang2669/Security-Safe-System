module SSS(
  input logic CLK, CPU_RESETN,
  input logic BTNC, BTNU, BTNL, BTNR, BTND,
  input logic [15:0] SW,
  output logic LED16_B, LED16_G, LED16_R,
  output logic CA, CB, CC, CD, CE, CF, CG, DP,
  output logic [7:0] AN,
  output logic [15:0] LED
);

logic [4:0] attempt_count;
logic [7:0] input_password, password, ssd;
logic [31:0] CLK_counter, CLK2_counter;

typedef enum logic [2:0] { S0, S0_0, S0_1, S1, S1_0, LOCK, OPEN } state_t;
state_t state, next_state;

assign input_password = SW[7:0];
assign LED = 16'hFFFF >> attempt_count;
assign {LED16_B, LED16_G, LED16_R} = state == OPEN ? 3'b010 : 3'b001;
assign {CA, CB, CC, CD, CE, CF, CG, DP} = ~ssd;

always_ff @(posedge CLK, negedge CPU_RESETN) begin
  if (~CPU_RESETN) begin
    state <= S0;
    attempt_count <= 0;
    password <= 8'b10011001;
    CLK_counter <= 0; CLK2_counter <= 0;
  end
  else begin
    if (state != next_state) begin
      CLK_counter <= 0;
      CLK2_counter <= 0;
    end
    else begin
      CLK_counter <= CLK_counter + 1;
      if (CLK_counter == 50000) begin
        CLK_counter <= 0;
        CLK2_counter <= CLK2_counter + 1;
      end
    end
    
    state <= next_state;
    if (state == S0 & BTNC) attempt_count <= attempt_count + 1;
    if (state == S1 & BTNR & ~(input_password == 0 | input_password == 8'b11111111 | input_password == 8'b10101010 | input_password == 8'b01010101)) password <= input_password;
  end
end

always_comb begin
  next_state = state;
  AN = 8'b11111111;
  ssd = 0;
  
  case (state)
    S0: begin
      if (attempt_count == 5'b10000) next_state = LOCK;
      else if (BTNC) next_state = input_password == password ? S0_1 : S0_0;
      else if (BTNL) next_state = S1;
      case (CLK2_counter[2:0])
        0: begin AN[7] = 0; ssd = 8'b01111100; end // V
        1: begin AN[6] = 0; ssd = 8'b11101110; end // A
        2: begin AN[5] = 0; ssd = 8'b10011100; end // C
        3: begin AN[4] = 0; ssd = 8'b11101110; end // A
        4: begin AN[3] = 0; ssd = 8'b00101010; end // n
        5: begin AN[2] = 0; ssd = 8'b00011110; end // t
      endcase
    end
    S0_0: begin
      if (CLK2_counter == 5000) next_state = S0;
      case (CLK2_counter[2:0])
        0: begin AN[7] = 0; ssd = 8'b10011110; end // E
        1: begin AN[6] = 0; ssd = 8'b00001010; end // r
        2: begin AN[5] = 0; ssd = 8'b00001010; end // r
        3: begin AN[4] = 0; ssd = 8'b11111100; end // O
        4: begin AN[3] = 0; ssd = 8'b00001010; end // r
      endcase
    end
    S0_1: begin
      if (CLK2_counter == 10000) next_state = OPEN;
      if (CLK2_counter < 5000)
        case (CLK2_counter[10:8])
          0, 1: begin AN = 0; ssd = 8'b10000000; end
          2: begin AN = 0; ssd = 8'b01000000; end
          3: begin AN = 0; ssd = 8'b00100000; end
          4, 5: begin AN = 0; ssd = 8'b00010000; end
          6: begin AN = 0; ssd = 8'b00001000; end
          7: begin AN = 0; ssd = 8'b00000100; end
        endcase
      else if (CLK2_counter[9]) begin AN = 0; ssd = 8'b11100000; end
    end
    
    S1: begin
      if (BTNR) next_state = (input_password == 0 | input_password == 8'b11111111 | input_password == 8'b10101010 | input_password == 8'b01010101) ? S1_0 : S0;
      else if (BTNU) next_state = S0;
    end
    S1_0: begin
      if (CLK2_counter == 5000) next_state = S1;
      case (CLK2_counter[2:0])
        0: begin AN[7] = 0; ssd = 8'b00111110; end // b
        1: begin AN[6] = 0; ssd = 8'b11101110; end // A
        2: begin AN[5] = 0; ssd = 8'b01111010; end // d
      endcase
    end
    
    LOCK: begin
      next_state = LOCK;
      case (CLK2_counter[2:0])
        0: begin AN[7] = 0; ssd = 8'b00011100; end // L
        1: begin AN[6] = 0; ssd = 8'b11111100; end // O
        2: begin AN[5] = 0; ssd = 8'b10011100; end // C
        3: begin AN[4] = 0; ssd = 8'b01101110; end // K
      endcase
    end
    
    OPEN: begin
      next_state = OPEN;
      case (CLK2_counter[2:0])
        0: begin AN[7] = 0; ssd = 8'b11111100; end // O
        1: begin AN[6] = 0; ssd = 8'b11001110; end // P
        2: begin AN[5] = 0; ssd = 8'b10011110; end // E
        3: begin AN[4] = 0; ssd = 8'b00101010; end // n
      endcase
    end
  endcase
end

endmodule
