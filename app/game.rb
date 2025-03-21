class Tile
    attr_sprite
    attr_accessor :sx, :sy, :status, :name

    def initialize vals
        @name = vals.name || "Undefined"
        @sx = nil
        @sy = nil
        @x = vals.x || 0
        @y = vals.y || 0
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
        @frames = 8
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

    def to_str
        "(#{@x}, #{@y}, #{@w}, #{@h}), #{@status}, (#{@sx}, #{@sy})"
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
        @swap = []
        @remove = []
        setup_tiles

    end

    def make_tile x, y, sy, w, h, name
        Tile.new({name: name, x:x*w, y:sy+y*h, path:"sprites/potions/bv_#{name}.png", start_frame: rand(7), frame_delay: rand(4) + 4})
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

    def adjacent? a, b
        if a.x == b.x
            return ((a.y == b.y-1) or (a.y == b.y+1))
        elsif a.y == b.y
            return ((a.x == b.x-1) or (a.x == b.x+1))
        else
            return false
        end
    end

    def animate_swap
        complete = false
        @swap.each do |s|
            t = @tiles[s]
            if t.x > t.sx
                t.x -= 2
            elsif t.x < t.sx
                t.x += 2
            end
            if t.y > t.sy
                t.y -= 2
            elsif t.y < t.sy
                t.y += 2
            end
            d = (t.sx - t.x).abs + (t.sy - t.y).abs
            if d > 40
                t.w -= 1
                t.h -= 1
            elsif d < 40
                t.w += 1
                t.h += 1
            end

            if t.x == t.sx and t.y == t.sy
                t.sx = nil
                t.sy = nil
                t.status = :idle
                complete = true
            end
        end
        if complete
            t = @tiles[@swap[0]]
            @tiles[@swap[0]] = @tiles[@swap[1]]
            @tiles[@swap[1]] = t
            @swap = []
            @highlight = false
        end
    end

    def highlight_or_flag x, y
        if @tiles.has_key?([x,y])
            h = @highlight
            if (not h) or (not adjacent?({x:x,y:y}, {x:h.gx, y:h.gy}))
                tx = x * @tile_w
                ty = (y * @tile_h) + @min_y
                @highlight = {gx:x, gy:y, x:tx, y:ty, w:@tile_w, h:@tile_h, r:255, g:255, b:0, a:128}.solid!
            else
                t0 = @tiles[[x,y]]
                t1 = @tiles[[h.gx, h.gy]]

                t0.sx = t1.x
                t0.sy = t1.y
                t0.status = :swap

                t1.sx = t0.x
                t1.sy = t0.y
                t1.status = :swap
                @swap = [[x,y],[h.gx, h.gy]]
            end
        end
    end

    def check_vertical x, y
        ref = @tiles[[x,y]].name
        linked = [[x,y]]
        ty = y +1
        while ty < @h
            if @tiles.has_key?([x,ty]) and @tiles[[x,ty]].name == ref
                linked << [x,ty]
            else
                break
            end
            ty += 1
        end

        ty = y -1
        while ty > 0
            if @tiles.has_key?([x,ty]) and @tiles[[x,ty]].name == ref
                linked << [x,ty]
            else
                break
            end
            ty -= 1
        end
        return linked
    end

    def check_horizontal x, y
        ref = @tiles[[x,y]].name
        linked = [[x,y]]
        tx = x +1
        while tx < @w
            if @tiles.has_key?([tx,y]) and @tiles[[tx,y]].name == ref
                linked << [tx,y]
            else
                break
            end
            tx += 1
        end

        tx = x -1
        while tx > 0
            if @tiles.has_key?([tx,y]) and @tiles[[tx,y]].name == ref
                linked << [tx,y]
            else
                break
            end
            tx -= 1
        end
        return linked
    end

    def find_groups
        out = []
        (0...@h).each do |y|
            (0...@w).each do |x|
                if @tiles.has_key?([x,y])
                    a = check_horizontal(x, y)
                    b = check_vertical(x, y)
                    adj = []
                    if a.size > 3
                        adj += a
                    end
                    if  b.size > 3
                        adj += b
                    end
                    adj = adj.select{ |t| not out.include?(t)}
                    out += adj
                end
            end
        end
        out
    end

    def drop
        changed = false
        (1...@h).each do |y|
            (0...@w).each do |x|
                if @tiles.has_key?([x,y])
                    if not @tile.has_key?([x, y-1])
                        #
                    end
                end
            end
        end
    end

    def tick
        if @swap != []
            animate_swap
            return
        end
        if @remove != []
            next_r = []
            @remove.each do |r|
                @tiles[r].w-=1
                @tiles[r].h-=1
                if @tiles[r].h <= 0 || @tiles[r].w <= 0
                    @tiles.delete(r)
                else
                    next_r << r
                end
            end
            @remove = next_r.dup
            return
        end

        @tiles.each {|t| t[1].tick()}

        clicked_tile = get_click()

        if clicked_tile
            highlight_or_flag(clicked_tile.x, clicked_tile.y)
        end

        @remove = find_groups
        @remove.each do |r|
            @tiles[r].status = :remove
        end
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
