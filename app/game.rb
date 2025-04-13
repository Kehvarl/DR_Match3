require '/app/tile.rb'

class Grid
    def initialize args
        @score = 0
        @mouse = args.inputs.mouse
        @args = args
        @tiles = {}
        @w = 9
        @h = 9
        @tile_w = 80
        @tile_h = 80
        @min_y = 480
        @highlight = false
        @state = :game
        @swap = []
        @swap_tick = 0
        @remove = []
        @remove_start = 0
        @drop = []
        @drop_tick = 0
        @fill = []
        @fill_start = 0
        @vy = 5
        setup_tiles

    end

    def make_tile x, y, sy, w, h, name
        type = [
            {name:'bv', tw:22, th:37, frames:8},
            {name:'gp', tw:24, th:39, frames:12},
            ].sample()
        Tile.new({name: type.name + name, x:x*w, y:sy+y*h, path:"sprites/potions/#{type.name}_#{name}.png",
                  tile_h:type.th, tile_w:type.tw,
                  frames:type.frames, start_frame: rand(7), frame_delay: rand(4) + 4})
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
        if @swap.any?
            duration = 40.0

            perc = Easing.smooth_step(initial: 0, final: 1, perc: @swap_tick / duration, power: 2)

            complete = true

            @swap.each do |pos|
                tile = @tiles[pos]
                next unless tile

                tile.x = Easing.smooth_step(initial: tile.start_x, final: tile.tx, perc: perc, power: 2)
                tile.y = Easing.smooth_step(initial: tile.start_y, final: tile.ty, perc: perc, power: 2)


                if perc < 0.5
                    scale = Easing.smooth_stop(initial: 1.0, final: 0.8, perc: perc * 2, power: 2)
                else
                    scale = Easing.smooth_start(initial: 0.8, final: 1.0, perc: (perc - 0.5) * 2, power: 2)
                end


                tile.w = (tile.default_w * scale).round
                tile.h = (tile.default_h * scale).round

                complete = false if (tile.x - tile.tx).abs > 1 || (tile.y - tile.ty).abs > 1
            end

            @swap_tick += 1

            if complete || @swap_tick >= duration
                pos1, pos2 = @swap
                @tiles[pos1], @tiles[pos2] = @tiles[pos2], @tiles[pos1]

                [pos1, pos2].each do |pos|
                    tile = @tiles[pos]
                    tile.x = tile.tx
                    tile.y = tile.ty
                    tile.tx = nil
                    tile.ty = nil
                    tile.start_x = tile.x
                    tile.start_y = tile.y
                    tile.w = tile.default_w
                    tile.h = tile.default_h
                    tile.status = :idle
                end

                @swap = []
                @swap_tick = 0
                @highlight = false
            end
        else
            @state = :remove
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

                t0.swap_setup t1.x, t1.y
                t1.swap_setup t0.x, t0.y

                @swap = [[x,y],[h.gx, h.gy]]
                @swap_tick = 0
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
                @tiles[[x, stack_y]].start_y = @tiles[[x, stack_y]].y
                @tiles[[x, stack_y]].ease_tick = @args.tick_count
                @drop << [x, stack_y]
                stack_y += 1
            end
        end
    end

    def remove_tick
        if @remove.any?
            @remove.reject! do |r|
                scale = Easing.smooth_stop(start_at: @remove_start, end_at: @remove_start+60,
                                        tick_count: @args.state.clock, power: 2)

                @tiles[r].w = (@tiles[r].default_w * (1-scale)).round
                @tiles[r].h = (@tiles[r].default_h * (1-scale)).round
                if @tiles[r].w <= 0 || @tiles[r].h <= 0
                    score = @tiles[r].score
                    if @remove.size > 4
                        score += (@remove.size - 4) * 20
                    end
                    @score += score
                    @tiles.delete(r)
                    true
                else
                    false
                end
            end
        else
            find_drops
            @state = :drop
        end
    end

    def drop_tick
        if @drop.any?
            next_d = []
            @drop.each do |d|
                if @tiles.has_key?(d)
                    perc = (@args.tick_count - @tiles[d].ease_tick) / 30
                    perc = 1.0 if perc > 1.0

                    @tiles[d].y = Easing.smooth_step(initial: @tiles[d].start_y,
                                                     final: @tiles[d].ty,
                                                     perc: perc, power: 2)

                    if perc < 1.0
                        next_d << d
                    else
                        new_pos = [d[0], @tiles[d].tgy]
                        @tiles[d].y = @tiles[d].ty
                        @tiles[d].tx = @tiles[d].ty = @tiles[d].tgy = @tiles[d].start_y = @tiles[d].ease_tick = nil
                        temp = @tiles[d]
                        @tiles.delete(d)
                        @tiles[new_pos] = temp
                    end
                end
            end
            @drop = next_d.dup
        else
            (0...@h).each do |y|
                (0...@w).each do |x|
                    next if @tiles.has_key?([x, y])
                    @fill << [x,y]
                    @tiles[[x, y]] = make_tile(x, y, @min_y, @tile_w, @tile_h, ['green', 'red', 'black', 'blue'].sample)
                    @tiles[[x, y]].w = 0
                    @tiles[[x, y]].h = 0
                    @fill_start = @args.tick_count
                end
            end
            @state = :fill
        end
    end

    def fill_tick
        if @fill.any?
            @fill.reject! do |f|

                scale = Easing.smooth_stop(start_at: @fill_start, end_at: @fill_start+30,
                                        tick_count: @args.state.clock, power: 2)

                @tiles[f].w = (@tiles[f].default_w * scale).round
                @tiles[f].h = (@tiles[f].default_h * scale).round

                @tiles[f].w == @tiles[f].default_w && @tiles[f].h == @tiles[f].default_h
            end
        else
            @state = :game
        end
    end


    def tick
        @tiles.each {|t| t[1].tick}

        case @state
        when :swap
            animate_swap
            return

        when :remove
            remove_tick
            return

        when :drop
            drop_tick
            return

        when :fill
            fill_tick
            return

        when :game
            if (clicked_tile = get_click())
                highlight_or_flag(clicked_tile.x, clicked_tile.y)
            end

            @remove = find_groups
            if @remove.any?
                @remove_start = @args.tick_count
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
        out << {x:0, y:@min_y - 50, size_enum:5, text:"Score: #{@score}", r:255, g:255, b:255}.label!
        out
    end
end
