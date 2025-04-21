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
        @match_count = 3
        @color_score_modifier  = 1.0
        @bottle_score_modifier = 1.0
        @both_score_modifier   = 1.5
        @highlight = false
        @state = :game
        @swap = []
        @remove = []
        @drop = []
        @fill = []
        @cascade_count = 0
        @cascade_active = false
        setup_tiles
    end

    def make_tile x, y, sy, w, h
        bottle = [
            {name:'bv', tw:22, th:37, frames:8},
            {name:'gp', tw:24, th:39, frames:12},
            ].sample()
        color = ['green', 'red', 'black', 'blue'].sample()
        Tile.new({name: bottle.name + color, color: color, bottle: bottle.name,
          x:x*w, y:sy+y*h, path:"sprites/potions/#{bottle.name}_#{color}.png",
                  tile_h:bottle.th, tile_w:bottle.tw,
                  frames:bottle.frames, start_frame: rand(7), frame_delay: rand(4) + 4})
    end

    def setup_tiles
        @tiles = {}
        (0...@h).each do |y|
            (0...@w).each do |x|
                @tiles[[x,y]] = make_tile(x, y, @min_y, @tile_w, @tile_h)
            end
        end
    end

    def get_click
        if not @mouse.click
            return false
        end

        point = @mouse.click.point

        x = (point.x / @tile_w).to_i
        y = ((point.y - @min_y) / @tile_h).to_i
        [x,y]
    end

    def adjacent? a, b
        dx = (a.x - b.x).abs
        dy = (a.y - b.y).abs
        (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    end

    def highlight_or_flag x, y
        if not @tiles.has_key?([x,y])
          return
        end

        h = @highlight
        if (not h) or (not adjacent?({x:x,y:y}, {x:h.gx, y:h.gy}))
            tx = x * @tile_w
            ty = (y * @tile_h) + @min_y
            @highlight = {gx:x, gy:y, x:tx, y:ty, w:@tile_w, h:@tile_h, r:255, g:255, b:0, a:128}.solid!
        else
            t0 = @tiles[[x,y]]
            t1 = @tiles[[h.gx, h.gy]]

            t0.start_swap_to(t1.x, t1.y)
            t1.start_swap_to(t0.x, t0.y)

            @swap = [[x,y],[h.gx, h.gy]]
            @swap_tick = 0
            @state = :swap
            @highlight = false
        end
    end

    def scan_line_for_type(x, y, dx, dy, type)
      ref = @tiles[[x, y]]
      return [] unless ref

      value = case type
              when :color then ref.color
              when :bottle then ref.bottle
              when :both then [ref.color, ref.bottle]
              end

      coords = [[x, y]]
      tx, ty = x + dx, y + dy

      while tx.between?(0, @w - 1) && ty.between?(0, @h - 1)
        tile = @tiles[[tx, ty]]
        break unless tile

        match = case type
                when :color then tile.color == value
                when :bottle then tile.bottle == value
                when :both then [tile.color, tile.bottle] == value
                end

        break unless match
        coords << [tx, ty]
        tx += dx
        ty += dy
      end

      coords
    end

    def merge_match_types(existing, new_type)
      return new_type unless existing
      return existing if existing == new_type
      :both
    end

    def get_match_type(tiles)
      colors = tiles.map(&:color).uniq
      bottles = tiles.map(&:bottle).uniq

      if colors.size == 1 && bottles.size == 1
        :both
      elsif colors.size == 1
        :color
      elsif bottles.size == 1
        :bottle
      else
        nil
      end
    end

    def find_groups
      out = {}

      [:color, :bottle, :both].each do |type|
        (0...@h).each do |y|
          (0...@w).each do |x|
            next unless @tiles.has_key?([x, y])

            horiz = (scan_line_for_type(x, y, 1, 0, type) + scan_line_for_type(x, y, -1, 0, type)).uniq
            vert  = (scan_line_for_type(x, y, 0, 1, type) + scan_line_for_type(x, y, 0, -1, type)).uniq

            [horiz, vert].each do |coords|
              next if coords.size < @match_count

              coords.each do |tile_coord|
                out[tile_coord] = merge_match_types(out[tile_coord], type)
              end
            end
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
          tile = @tiles[[x, stack_y]]
          tile.start_drop_to(drop_y + (stack_y - y), tile.y - max_fall[x])

          @drop << [x, stack_y]
          stack_y += 1
        end
      end
    end


    def calculate_score(tile, match_type)
        base_score = tile.score

        color_mod  = @color_score_modifier  || 1.0
        bottle_mod = @bottle_score_modifier || 1.0
        both_mod   = @both_score_modifier   || 1.5

        modifier = case match_type
                   when :color  then color_mod
                   when :bottle then bottle_mod
                   when :both   then both_mod
                   else 1.0
                   end

        score = base_score * modifier
        score += (@remove.size - 4) * 20 if @remove.size > 4
        score += @cascade_count * 10 if @cascade_count > 0

        score.to_i
    end

    def remove_tick
        if @remove.any?
          puts @remove
            @remove.reject! do |r, match_type|
                tile = @tiles[r]
                if tile.removal_done?
                    @score += calculate_score(tile, match_type)
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
            @drop.reject! do |d|
                tile = @tiles[d]
                next true unless tile
                if tile.idle?
                    new_pos = [d[0], tile.tgy]
                    @tiles.delete(d)
                    @tiles[new_pos] = tile
                    true
                else
                  false
                end
              end
          else
            (0...@h).each do |y|
                (0...@w).each do |x|
                    next if @tiles.has_key?([x, y])
                    @fill << [x, y]
                    @tiles[[x, y]] = make_tile(x, y, @min_y, @tile_w, @tile_h)
                    @tiles[[x, y]].w = 0
                    @tiles[[x, y]].h = 0
                    @tiles[[x, y]].start_fill
                end
            end
            @state = :fill
        end
    end

    def fill_tick
        if @fill.any?
            @fill.reject!{|f| not @tiles[f].animating?}
        else
            @remove = find_groups
            if @remove.any?
                @remove.each { |r, match_type| @tiles[r].start_removal! }
                @remove_start = @args.tick_count
                @state = :remove
                @cascade_active = true
                @cascade_count += 1
            else
                if @cascade_active
                    @cascade_active = false
                    @cascade_count = 0
                end
                @state = :game
            end
        end
    end

    def tick
        @tiles.each {|t| t[1].tick}

        case @state
        when :swap
            if @swap.any?
                pos1, pos2 = @swap
                if @tiles[pos1].status == :idle and @tiles[pos2].status == :idle

                    @tiles[pos1], @tiles[pos2] = @tiles[pos2], @tiles[pos1]
                    @swap = []
                    @swap_tick = 0
                    @highlight = false
                end
            else
                @state = :remove
            end
        when :remove
            remove_tick
        when :drop
            drop_tick
        when :fill
            fill_tick
        when :game
            if (clicked_tile = get_click())
                highlight_or_flag(clicked_tile.x, clicked_tile.y)
            end

            @remove = find_groups
            if @remove.any?
                @remove.each { |r, match_type| @tiles[r].start_removal! }
                @remove_start = @args.tick_count
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
