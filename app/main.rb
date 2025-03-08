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
    if args.state.grid[[x,ty]].name == ref
      linked << [x,ty]
    else
      break
    end
    ty += 1
  end

  ty = y -1
  while ty > 0
    if args.state.grid[[x,ty]].name == ref
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
    if args.state.grid[[tx,y]].name == ref
      linked << [tx,y]
    else
      break
    end
    tx += 1
  end

  tx = x -1
  while tx > 0
    if args.state.grid[[tx,y]].name == ref
      linked << [tx,y]
    else
      break
    end
    tx -= 1
  end
  return linked
end

def find_groups args
  (0...args.state.grid_h).each do |y|
    (0...args.state.grid_w).each do |x|
      # puts "#{x}, #{y}  - H: #{check_horizontal args, x, y}"
      # puts "#{x}, #{y}  - V: #{check_vertical args, x, y}"
    end
  end
end

def adjacent? a, b
  if a.x == b.gx
    return (a.y == b.gy-1) or (a.y == b.gy+1)
  elsif a.y == b.gy
    return (a.x == b.gx-1) or (a.x == b.gx+1)
  else
    return false
  end
end

def tick args
  if args.tick_count == 0
    init args
  end

  if args.inputs.mouse.click
    point = args.inputs.mouse.click.point

    x = (point.x / args.state.tile_size).to_i
    y = ((point.y - args.state.starting_height) / args.state.tile_size).to_i
    if args.state.grid.has_key?([x,y])
      h = args.state.highlight
      if (not h) or not adjacent?({x:x, y:y}, h)
        s = args.state.tile_size
        tx = x * s
        ty = (y * s) + args.state.starting_height
        args.state.highlight = {gx:x, gy:y, x:tx, y:ty, w:s, h:s, r:255, g:255, b:0, a:128}.solid!
      else
        temp = args.state.grid[[x,y]].dup
        args.state.grid[[x,y]] = args.state.grid[[h.gx,h.gy]].dup
        args.state.grid[[h.gx,h.gy]] = temp
        args.state.highlight = false
      end
    end
  end

  find_groups args

  args.outputs.primitives << {x:0, y:0, w:720, h:1280, r:0, g:0, b:0}.solid!
  draw_grid args
  if args.state.highlight
    args.outputs.primitives << args.state.highlight
  end
end
