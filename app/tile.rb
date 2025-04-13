class Tile
    attr_sprite
    attr_accessor :start_x, :start_y, :ease_tick, :tx, :ty, :tgy, :status,
                :name, :score, :default_w, :default_h

    def initialize(vals)
        @name = vals.name || "Undefined"
        @score = vals.score || 10

        @x = vals.x || 0
        @y = vals.y || 0
        @start_x = @x
        @start_y = @y

        @ease_tick = 0
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
        @destination_y = @y
        @status = :idle

        @frames = vals.frames || 8
        @current_frame = vals.start_frame || 0
        @frame_delay = vals.frame_delay || 10
        @current_delay = @frame_delay

        # Center tile within slot
        @x += (@s - @w).div(2)

        # Movement targets
        @tx = nil
        @ty = nil
        @tgy = nil
    end

    def tick
        animate_idle
        case @status
        when :swap then animate_swap
        when :drop then animate_drop
        when :fill then animate_fill
        end
    end

    def animate_idle
        @current_delay -= 1
        if @current_delay <= 0
            @current_delay = @frame_delay
            @current_frame = (@current_frame + 1) % @frames
            @tile_x = @tile_w * @current_frame
        end
    end

    def animate_swap
        animate_to(@tx, @ty, :swap)
    end

    def animate_drop
        animate_to(@x, @tgy, :drop, axis: :y)
    end

    def animate_fill
        animate_to(@x, @tgy, :fill, axis: :y)
    end

    def animate_to(target_x, target_y, type, axis: :both)
        @ease_tick += 1
        duration = 10
        if @ease_tick >= duration
            @x = target_x if axis == :x || axis == :both
            @y = target_y if axis == :y || axis == :both
            @status = :idle
            @ease_tick = 0
        else
            p = @ease_tick / duration.to_f
            e = p * p * (3 - 2 * p) # smootherstep
            @x = @start_x + ((target_x - @start_x) * e) if axis == :x || axis == :both
            @y = @start_y + ((target_y - @start_y) * e) if axis == :y || axis == :both
        end
    end

    def start_swap_to(tx, ty)
        @tx = tx
        @ty = ty
        @start_x = @x
        @start_y = @y
        @status = :swap
        @ease_tick = 0
    end

    def start_drop_to(tgy)
        @start_y = @y
        @tgy = tgy
        @status = :drop
        @ease_tick = 0
    end

    def start_fill_from(start_y, tgy)
        @start_y = start_y
        @tgy = tgy
        @y = start_y
        @status = :fill
        @ease_tick = 0
    end

    def idle?
        @status == :idle
    end

    def animating?
        [:drop, :swap, :fill].include?(@status)
    end

    def to_str
        "(#{@x}, #{@y}, #{@w}, #{@h}), #{@status}, (#{@tx}, #{@ty})"
    end
end
