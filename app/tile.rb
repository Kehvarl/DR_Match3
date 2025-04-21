class Tile
    attr_sprite
    attr_accessor :start_x, :start_y, :ease_tick, :tx, :ty, :tgy, :status,
                :name, :color, :bottle, :score, :default_w, :default_h

    def initialize(vals)
        @name = vals.name || "Undefined"
        @color = vals.color || "Undefined"
        @bottle = vals.bottle || "Undefined"
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

        @x += (@s - @w).div(2)

        @tx = nil
        @ty = nil
        @tgy = nil
    end

    def tick
        animate_idle
        case @status
        when :swap then animate_swap
        when :removing then animate_removal
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

    def animate_removal
        animate_scale(:removal)
    end

    def animate_drop
        animate_to(@x, @ty, :drop, axis: :y)
    end

    def animate_fill
        animate_scale(:fill)
    end

    def animate_scale(type)
        duration = 30
        e = Easing.smooth_step(
            start_at: @ease_tick,
            end_at: @ease_tick + duration,
            tick_count: Kernel.tick_count,
            power: 2
        )

        case type
        when :fill
            @w = (@default_w * e).round
            @h = (@default_h * e).round
        when :removal
            @w = (@start_w * (1 - e)).round
            @h = (@start_h * (1 - e)).round
        end

        if (@w == @default_w && @h == @default_h) || (@w <= 0 || @h <= 0)
            @status = :idle if type == :fill
            @status = :removed if type == :removal
        end
    end

    def animate_to(target_x, target_y, type, axis: :both)
        duration = 30
        e = Easing.smooth_step(
            start_at: @ease_tick,
            end_at: @ease_tick + duration,
            tick_count: Kernel.tick_count
        )

        case axis
        when :x, :both
            @x = @start_x + ((target_x - @start_x) * e)
        end
        case axis
        when :y, :both
            @y = @start_y + ((target_y - @start_y) * e)
        end

        if Kernel.tick_count >= @ease_tick + duration
            @x = target_x if axis == :x || axis == :both
            @y = target_y if axis == :y || axis == :both
            @status = :idle
            @ease_tick = 0
        end
    end

    def start_swap_to(tx, ty)
        @tx = tx
        @ty = ty
        @start_x = @x
        @start_y = @y
        @status = :swap
        @ease_tick = Kernel.tick_count
    end

    def start_removal!
        @ease_tick = Kernel.tick_count
        @start_w = @w
        @start_h = @h
        @status = :removing
    end

    def start_drop_to(tgy, ty)
        @start_y = @y
        @tgy = tgy
        @ty = ty
        @status = :drop
        @ease_tick = Kernel.tick_count
    end

    def start_fill
        @status = :fill
        @ease_tick = Kernel.tick_count
    end

    def idle?
        @status == :idle
    end

    def animating?
        [:drop, :removing, :swap, :fill].include?(@status)
    end

    def removal_done?
        @status == :removed
    end

    def to_str
        "(#{@x}, #{@y}, #{@w}, #{@h}), #{@status}, (#{@tx}, #{@ty})"
    end
end
