def init args
  args.state.grid = {}
  args.state.grid_w = 9
  args.state.grid_h = 9
  args.state.tile_size = 80
  args.state.starting_height = 480
  args.state.highlight = false
  load_grid args
end

def make_tile x, y, sy, w, h, name
  {name: name, x:x*w, y:sy+y*h, w:w, h:h, path:"sprites/square/#{name}.png"}.sprite!
end

def load_grid args
  args.state.grid = {}
  tile_size = args.state.tile_size
  sy = args.state.starting_height
  (0...args.state.grid_h).each do |y|
    (0...args.state.grid_w).each do |x|
      args.state.grid[[x,y]] = make_tile(x, y, sy, tile_size, tile_size, ['green', 'red', 'violet'].sample)
    end
  end
end

def draw_grid args
  args.state.grid.each do |g|
    args.outputs.primitives << g[1]
  end
end

def check_vertical args, x, y
  ref = args.state.grid[[x,y]].name
  linked = [[x,y]]
  ty = y +1
  while ty < args.state.grid_h
    if args.state.grid.has_key?([x,ty]) and args.state.grid[[x,ty]].name == ref
      linked << [x,ty]
    else
      break
    end
    ty += 1
  end

  ty = y -1
  while ty > 0
    if args.state.grid.has_key?([x,ty]) and args.state.grid[[x,ty]].name == ref
      linked << [x,ty]
    else
      break
    end
    ty -= 1
  end
  return linked
end

def check_horizontal args, x, y
  ref = args.state.grid[[x,y]].name
  linked = [x,y]
  tx = x +1
  while tx < args.state.grid_w
    if args.state.grid.has_key?([tx,y]) and args.state.grid[[tx,y]].name == ref
      linked << [tx,y]
    else
      break
    end
    tx += 1
  end

  tx = x -1
  while tx > 0
    if args.state.grid.has_key?([tx,y]) and args.state.grid[[tx,y]].name == ref
      linked << [tx,y]
    else
      break
    end
    tx -= 1
  end
  return linked
end

def find_groups args
  out = []
  (0...args.state.grid_h).each do |y|
    (0...args.state.grid_w).each do |x|
      if args.state.grid.has_key?([x,y])
        a = check_horizontal(args, x, y)
        b = (check_vertical args, x, y)
        if a.size > 3 || b.size > 2
          adj = a + b
          adj = adj.select{ |t| not out.include?(t)}
          out += adj
        end
      end
    end
  end
  out
end

def drop args
  changed = false
  (1...args.state.grid_h).each do |y|
    (0...args.state.grid_w).each do |x|
      if args.state.grid.has_key?([x,y])
        if not args.state.grid.has_key?([x, y-1])
          ta = args.state.grid[[x,y]].dup
          ta.y -= args.state.tile_size
          args.state.grid.delete([x,y])
          args.state.grid[[x,y-1]] = ta
          changed = true
        end
      end
    end
  end
  if changed
    drop args
  end
end

def adjacent? a, b
  if a.x == b.x
    return (a.y == b.y-1) or (a.y == b.y+1)
  elsif a.y == b.y
    return (a.x == b.x-1) or (a.x == b.x+1)
  else
    return false
  end
end

def do_swap args, a, b
  ta = args.state.grid[a].dup
  tb = args.state.grid[b].dup
  tx = ta.x
  ty = ta.y
  ta.x = tb.x
  ta.y = tb.y
  tb.x = tx
  tb.y = ty
  args.state.grid[a] = tb
  args.state.grid[b] = ta
  args.state.highlight = false
end

def get_click args
  if args.inputs.mouse.click
    point = args.inputs.mouse.click.point

    x = (point.x / args.state.tile_size).to_i
    y = ((point.y - args.state.starting_height) / args.state.tile_size).to_i
    if args.state.grid.has_key?([x,y])
      h = args.state.highlight
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
end


def tick args
  if args.tick_count == 0
    init args
  end

  get_click(args)

  find_groups(args).each do |tile|
    args.state.grid.delete(tile)
  end

  drop args

  # Fill in Empty Spaces

  args.outputs.primitives << {x:0, y:0, w:720, h:1280, r:0, g:0, b:0}.solid!
  draw_grid args
  if args.state.highlight
    args.outputs.primitives << args.state.highlight
  end
end
