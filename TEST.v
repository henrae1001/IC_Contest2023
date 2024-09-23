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
//-----------------------------------------------------------------------
reg [2:0] state,next_state;

localparam IDLE = 3'd0;
localparam READ_MAP =3'd1;
localparam MOVE_CAL1= 3'd2;
localparam MOVE_CAL2= 3'd3;
localparam FINISH = 3'd3;

reg [3:0] map_x[39:0];
reg [3:0] map_y[39:0];
reg [7:0] map_counter;
//reg [7:0] count_x_step,count_y_step;
reg [7:0] count_x,count_y;

reg [7:0] count_x_max,count_y_max;
reg [7:0] maxxy_pos,maxab_pos;
reg [7:0] count1,count2;//7:4-y,3:0-x ????

wire [3:0] x1,y1,x2,y2;//circle center
assign x1 = count1[3:0];//first circle
assign y1 = count1[7:4];
assign x2 = count2[3:0];//second circle
assign y2 = count2[7:4];

wire [7:0] len1,len2;
assign len1 = (map_x[map_counter]-x1)*(map_x[map_counter]-x1)+(map_y[map_counter]-y1)*(map_y[map_counter]-y1);
assign len2 = (map_x[map_counter]-x2)*(map_x[map_counter]-x2)+(map_y[map_counter]-y2)*(map_y[map_counter]-y2);

wire in1 = (len1 <= 16)?1:0;
wire in2 = (len2 <= 16)?1:0;

always@(*)
begin
    case (state)
    IDLE: if(RST) next_state = READ_MAP;
    READ_MAP:
    begin
        if(map_counter==39) next_state = MOVE_CAL1;//??
    end
    MOVE_CAL1:
    begin
        if(count1==8'd255) next_state = FINISH;
        next_state = MOVE_CAL2; 
    end
    MOVE_CAL2:
    begin
        if(count2==8'd0) next_state = FINISH;
        next_state = MOVE_CAL1;
    end
    endcase
end
always@(posedge CLK)
begin
    if(RST) state <= IDLE;
    else state <= next_state;
end
always@(posedge CLK)
begin
    case (state)
    IDLE:
    begin
        count1 <= 8'd0;
        count2 <= 8'd255;
        count_x_max <= 8'd0;
        count_y_max <= 8'd0;
        map_counter <= 8'd0;
        maxxy_pos <= 8'd0;
        maxab_pos <= 8'd255;
        DONE <= 0;
    end
    READ_MAP:
    begin
        map_x[map_counter] <= X;
        map_y[map_counter] <= Y;
        if(map_counter==8'd39)
        begin
            map_counter <= 0;
        end
        else map_counter <= map_counter + 1;
    end
    MOVE_CAL1:
    begin
        count1 <= count1 + 1;//C1++
        if(map_counter==8'd39) begin
            map_counter <= 0;
            state <= next_state;
        end
        else begin
            map_counter <= map_counter + 1;
            if(in1) count_x <= count_x + 1;
        end
        if(count1==255) begin
            if(count_x>count_x_max)
            begin
                count_x_max <= count_x;
                maxxy_pos <= count1;
            end
        end
    end
    MOVE_CAL2:
    begin
        count2 <= count2 - 1;//C2--
        if(map_counter==8'd39) begin
            map_counter <= 0;
            state <= next_state;
        end
        else begin
            map_counter <= map_counter + 1;
            if(in2) count_y <= count_y + 1;
        end
        if(count2==255) begin
            if(count_y>count_y_max)
            begin
                count_y_max <= count_y;
                maxab_pos <= count2;
            end
        end
    end
    FINISH:
    begin
        C1X <= maxxy_pos[3:0];
        C1Y <= maxxy_pos[7:4];
        C2X <= maxab_pos[3:0];
        C2Y <= maxab_pos[7:4];
        DONE <= 1;
    end
    default: begin end
    endcase
end

//-----------------------------------------------------------------------
endmodule