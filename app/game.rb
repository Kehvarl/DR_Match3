class Tile
    attr_sprite

    def initialize vals
        @name = vals.name || "Undefined"
        @x = vals.x || 0
        @y = vals.y || 0
        @w = vals.w || 44
        @h = vals.h || 70
        @tile_w = 22
        @tile_h = 37
        @tile_x = 0
        @tile_y = 0
        @path = vals.path || "sprites/misc/explosion-0.png"
        @default_w = @w
        @default_h = @h
        @destination_x = @x
        @destinatin_y = @y
        @status = :idle
        @frames = 8
        @current_frame = 0
        @frame_delay = 10
        @current_delay = 10

    end

    def idle
        @current_delay -= 1
        if @current_delay <= 0
            @current_delay = @frame_delay
            @current_frame = (@current_frame + 1)%@frames
            @tile_x = @tile_w * @current_frame
        end
    end

    def swap_left
    end

    def swap_right
    end

    def swap_up
    end

    def swap_down
    end

    def slide_right
    end

    def fall_down
    end

    def tick
        idle()
    end
end

class Grid
    def initialize args
        @mouse = args.inputs.mouse
        @tiles = {}
        @w = 9
        @h = 9
        @tile_w = 80
        @tile_h = 80
        @min_y = 480
        @highlight = false
        setup_tiles

    end

    def make_tile x, y, sy, w, h, name
        Tile.new({name: name, x:x*w, y:sy+y*h, path:"sprites/potions/bv_#{name}.png"})
    end

    def setup_tiles
        @tiles = {}
        (0...@h).each do |y|
            (0...@w).each do |x|
                @tiles[[x,y]] = make_tile(x, y, @min_y, @tile_w, @tile_h, ['green', 'red', 'black', 'blue'].sample)
            end
        end
    end

    def get_click
        if @mouse.click
            point = @mouse.click.point

            x = (point.x / @tile_w).to_i
            y = ((point.y - @min_y) / @tile_h).to_i
            return [x,y]
        end
        return false
    end

    def highlight tile
        if @tiles.has_key?([x,y])
            h = @highlight
            if (not h) or not adjacent?({x:x,y:y}, {x:h.gx, y:h.gy})
                s = args.state.tile_size
                tx = x * s
                ty = (y * s) + args.state.starting_height
                args.state.highlight = {gx:x, gy:y, x:tx, y:ty, w:s, h:s, r:255, g:255, b:0, a:128}.solid!
            else
                do_swap(args, [x,y], [h.gx, h.gy])
            end
        end
    end

    def tick
        # Tick Tiles
        @tiles[[0,0]].tick()

        # get_click
        # Highlight or Find Swap
        # Flag Swap
        # Animate Swap
        # Find groups
        # Flag Groups
        # Animate Remove
        # Find Drops
        # Flag Drops
        # Animate Drops
        # Find Shifts
        # Flag Shifts
        # Animate Shifs
    end

    def render
        out = []
        @tiles.each do |t|
            out << t[1]
        end
        if @highlight
            out << @highlight
        end
        out
    end
end
