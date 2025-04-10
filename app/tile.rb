class Tile
    attr_sprite
    attr_accessor :start_x, :start_y, :tx, :ty, :tgy, :status, :name, :score, :default_w, :default_h

    def initialize vals
        @name = vals.name || "Undefined"
        @score = vals.score || 10
        @tx = nil
        @ty = nil
        @tgy = nil
        @x = vals.x || 0
        @y = vals.y || 0
        @start_x = @x
        @start_y = @y
        @s = vals.s || 80
        @w = vals.w || 50
        @h = vals.h || 74
        @tile_w = vals.tile_w || 22
        @tile_h = vals.tile_h || 37
        @tile_x = 0
        @tile_y = 0

        @path = vals.path || "sprites/misc/explosion-0.png"
        @default_w = @w
        @default_h = @h
        @destination_x = @x
        @destinatin_y = @y
        @status = :idle
        @frames = vals.frames||8
        @current_frame = vals.start_frame || 0
        @frame_delay = vals.frame_delay || 10
        @current_delay = @frame_delay
        @x += (@s - @w).div(2)
    end

    def idle
        @current_delay -= 1
        if @current_delay <= 0
            @current_delay = @frame_delay
            @current_frame = (@current_frame + 1)%@frames
            @tile_x = @tile_w * @current_frame
        end
    end

    def swap_setup tx, ty
        @tx = tx
        @ty = ty
        @start_x = @x
        @start_y = @y
        @status = :swap
    end

    def tick
        idle()
    end

    def to_str
        "(#{@x}, #{@y}, #{@w}, #{@h}), #{@status}, (#{@tx}, #{@ty})"
    end
end
