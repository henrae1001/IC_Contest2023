module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output reg DONE);
/*-------------------------------------------------------------------------*/
parameter 
idle = 3'd0,
read = 3'd1,
moveC1 = 3'd2,
moveC2 = 3'd3,
check = 3'd4,
finish = 3'd5;

parameter r2 = 17'd16;
wire [6:0] len1, len2;
wire in1, in2;

reg [3:0] targetX [39:0];
reg [3:0] targetY [39:0];
reg [5:0] count;
reg [5:0] covered;
reg [5:0] max_covered_1, max_covered_2;
reg optimise;
reg doingC1;
reg [3:0] xMax1, yMax1;
reg [3:0] xMax2, yMax2;
reg [2:0] state;
reg [2:0] nextState;

assign len1 = (C1X-targetX[count])*(C1X-targetX[count]) + (C1Y-targetY[count])*(C1Y-targetY[count]);
assign len2 = (C2X-targetX[count])*(C2X-targetX[count]) + (C2Y-targetY[count])*(C2Y-targetY[count]);

assign in1 = (len1 <= r2) ? 1 : 0;
assign in2 = (len2 <= r2) ? 1 : 0;

//next state logic
always @(*) begin
    case (state)
          idle  : begin 
            nextState <= read;
          end

          read  : begin 
            if (count == 7'd39) begin
                nextState <= check;
            end
            else begin
                nextState <= read;
            end
          end

          moveC1  : begin 
            nextState <= check;
          end

          moveC2  : begin 
            nextState <= check;
          end

          check : begin
            if (max_covered_1 != 0) begin
                if (max_covered_1 == max_covered_2) begin
                    nextState <= finish;
                end
                else begin
                   if (count == 7'd39) begin
                    if(doingC1)begin
                        if (C1X == 6'd15 && C1Y == 6'd15) begin
                            nextState <= moveC2;
                        end
                        else begin
                            nextState <= moveC1;
                        end
                    end
                    else begin
                        if (C2X == 6'd0 && C2Y == 6'd15) begin
                            nextState <= moveC1;
                        end
                        else begin
                            nextState <= moveC2;
                        end
                    end
                   end
                   else begin
                    nextState <= check;
                   end
                end
            end
            else begin
                nextState <= check;
            end
          end

          finish  : begin 
            nextState <= idle;
          end 
        endcase
end

//state register and data process
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        C1X <= 6'd0;
        C1Y <= 6'd0;
        C2X <= 6'd0;
        C2Y <= 6'd0;
        DONE <= 1'b0;
        covered <= 6'd0;
        count <= 7'd0;
        state <= idle;
        max_covered_1 <= 0;
        max_covered_2 <= 0;
        xMax1 <= 0;
        xMax2 <= 0;
        yMax1 <= 0;
        yMax2 <= 0;
        doingC1 <= 1;
        optimise <= 0;
    end
    else begin
        state <= nextState;

        case (state)
          idle  : begin 
            C1X <= xMax1;
            C1Y <= yMax1;
            C2X <= xMax2;
            C2Y <= yMax2;
            DONE <= 1'b0;
            covered <= 6'd0;
            count <= 7'd0;
          end

          read  : begin 
            targetX[count] <= X;
            targetY[count] <= Y;
            if (count == 7'd39) begin
                count <= 0;
            end
            else begin
             count <= count + 1;
            end
          end

          moveC1  : begin 
            covered <= 0;
            count <= 0;
            doingC1 <= 1;

            if (C2X == 6'd0 && C2Y == 6'd15) begin
                C2X <= xMax2;
                C2Y <= yMax2;
            end

            if (C1Y == 6'd15) begin
                if (C1X == 6'd15) begin
                    C1X <= xMax1;
                    C1Y <= yMax1;
                    doingC1 <= 0;
                end
                else begin
                    C1X <= C1X + 1;
                    C1Y <= 0;
                end
            end
            else begin
                C1Y <= C1Y + 1;
            end
          end

          moveC2  : begin 
            covered <= 0;
            count <= 0;
            doingC1 <= 0;

            if (C1X == 6'd15 && C1Y == 6'd15) begin
                 C1X <= xMax1;
                 C1Y <= yMax1;
            end

            if (C2Y == 6'd15) begin
                if (C2X == 6'd15) begin
                    C2X <= xMax2;
                    C2Y <= yMax2;
                    doingC1 <= 1;
                    if (optimise == 0) begin
                        optimise <= 1;
                    end
                end
                else begin
                    C2X <= C2X + 1;
                    C2Y <= 0;
                end
            end
            else begin
                C2Y <= C2Y + 1;
            end
          end

          check : begin
            if (count == 7'd39) begin
                count <= 0;
            end
            else begin
                count <= count + 1;
            end

            if (in1 || in2) begin
                covered <= covered + 1;
            end

            if (optimise == 1) begin
                if (covered >= max_covered_2) begin
                    max_covered_2 <= covered;
                    if (!doingC1) begin
                        xMax2 <= C2X;
                        yMax2 <= C2Y;
                    end
                    else begin
                        xMax1 <= C1X;
                        yMax1 <= C1Y;
                    end
                end
            end
            else begin
            if (covered >= max_covered_1) begin
                max_covered_1 <= covered;

                if (!doingC1) begin
                    xMax2 <= C2X;
                    yMax2 <= C2Y;
                end
                else begin
                    xMax1 <= C1X;
                    yMax1 <= C1Y;
                end
            end
            end
          end

          finish  : begin 
            DONE <= 1'b1;
          end 
        endcase
    end
end
/*-------------------------------------------------------------------------*/
endmodule


