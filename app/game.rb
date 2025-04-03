class Tile
    attr_sprite
    attr_accessor :tx, :ty, :tgy, :status, :name, :default_w, :default_h

    def initialize vals
        @name = vals.name || "Undefined"
        @tx = nil
        @ty = nil
        @tgy = nil
        @x = vals.x || 0
        @y = vals.y || 0
        @s = vals.s || 80
        @w = vals.w || 50
        @h = vals.h || 74
        @tile_w = vals.tile_w || 22
        @tile_h = vals.tile_h || 37
        @tile_x = 0
        @tile_y = 0
        @anchor_x = 0.5
        @anchor_y = 0.5
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
        "(#{@x}, #{@y}, #{@w}, #{@h}), #{@status}, (#{@tx}, #{@ty})"
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
        @state = :game
        @swap = []
        @remove = []
        @drop = []
        @fill = []
        @vy = 5
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
            if t.x > t.tx
                t.x -= @vy
            elsif t.x < t.tx
                t.x += @vy
            end
            if t.y > t.ty
                t.y -= @vy
            elsif t.y < t.ty
                t.y += @vy
            end
            d = (t.tx - t.x).abs + (t.ty - t.y).abs
            if d > 40
                t.w -= 1
                t.h -= 1
            elsif d < 40
                t.w += 1
                t.h += 1
            end

            if t.x == t.tx and t.y == t.ty
                t.tx = nil
                t.ty = nil
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

                t0.tx = t1.x
                t0.ty = t1.y
                t0.status = :swap

                t1.tx = t0.x
                t1.ty = t0.y
                t1.status = :swap
                @swap = [[x,y],[h.gx, h.gy]]
                @state = :swap
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

    def find_drops
        drop_tiles = []
        max_fall = {}

        (1...@h).each do |y|
            (0...@w).each do |x|
                next unless @tiles.has_key?([x, y]) && !@drop.include?([x, y])
                next if @tiles.has_key?([x, y - 1])

                drop_y = y
                while drop_y > 0 && !@tiles.has_key?([x, drop_y - 1])
                    drop_y -= 1
                end

                fall_distance = (y - drop_y) * @tile_h
                max_fall[x] = fall_distance if !max_fall[x] || fall_distance > max_fall[x]
                drop_tiles << [x, y, drop_y, fall_distance]
            end
        end

        drop_tiles.each do |x, y, drop_y, fall_distance|
            stack_y = y
            while @tiles.has_key?([x, stack_y])
                @tiles[[x, stack_y]].tgy = drop_y + (stack_y - y)
                @tiles[[x, stack_y]].ty = @tiles[[x, stack_y]].y - max_fall[x]
                @drop << [x, stack_y]
                stack_y += 1
            end
        end
    end

    def fill_tiles
        (0...@h).each do |y|
            (0...@w).each do |x|
                next if @tiles.has_key?([x, y])
                @fill << [x,y]
                @tiles[[x, y]] = make_tile(x, y, @min_y, @tile_w, @tile_h, ['green', 'red', 'black', 'blue'].sample)
                @tiles[[x, y]].w = 0
                @tiles[[x, y]].h = 0
            end
        end
    end

def tick
    case @state
    when :swap
        if @swap.any?
            animate_swap
        else
            @state = :remove
        end
        return

    when :remove
        if @remove.any?
            @remove.reject! do |r|
                @tiles[r].w -= 1
                @tiles[r].h -= 1
                if @tiles[r].w <= 0 || @tiles[r].h <= 0
                    @tiles.delete(r)
                    true
                else
                    false
                end
            end
        else
            find_drops  # Make sure drops are calculated
            @state = :drop
        end
        return if @remove.any?

    when :drop
        if @drop.any?
            next_d = []
            @drop.each do |d|
                if @tiles.has_key?(d)
                    if @tiles[d].y > @tiles[d].ty
                        @tiles[d].y -= @vy
                        next_d << d
                    else
                        temp = @tiles.delete(d)
                        @tiles[[d[0], temp.tgy]] = temp.dup if temp
                    end
                end
            end
            @drop = next_d.dup
        else
            fill_tiles  # Make sure new tiles are generated
            @state = :fill
        end
        return if @drop.any?

    when :fill
        if @fill.any?
            @fill.reject! do |f|
                @tiles[f].w += 1 if @tiles[f].w < @tiles[f].default_w
                @tiles[f].h += 1 if @tiles[f].h < @tiles[f].default_h

                @tiles[f].w = @tiles[f].default_w if @tiles[f].w > @tiles[f].default_w
                @tiles[f].h = @tiles[f].default_h if @tiles[f].h > @tiles[f].default_h

                @tiles[f].w == @tiles[f].default_w && @tiles[f].h == @tiles[f].default_h
            end
        else
            @state = :game
        end
        return if @fill.any?

    when :game
        @tiles.each_value(&:tick)

        if (clicked_tile = get_click())
            highlight_or_flag(clicked_tile.x, clicked_tile.y)
        end

        @remove = find_groups
        if @remove.any?
            @remove.each { |r| @tiles[r].status = :remove }
            @state = :remove
        end
    end
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
