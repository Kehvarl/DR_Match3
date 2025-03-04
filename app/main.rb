def init args
  args.state.grid = {}
  args.state.grid_w = 9
  args.state.grid_h = 9
  args.state.tile_size = 80
  args.state.starting_height = 480
  load_grid args
end

def make_tile x, y, sy, w, h, name
  {x:x*w, y:sy+y*h, w:w, h:h, path:"sprites/square/#{name}.png"}.sprite!
end

def load_grid args
  args.state.grid = {}
  tile_size = args.state.tile_size
  sy = args.state.starting_height
  (0...args.state.grid_h).each do |y|
    (0...args.state.grid_w).each do |x|
      args.state.grid[[x,y]] = make_tile(x, y, sy, tile_size, tile_size, 'green')
    end
  end
end

def draw_grid args
  args.state.grid.each do |g|
    args.outputs.primitives << g[1]
  end
end

def find_groups args
end

def tick args
  if args.tick_count == 0
    init args
  end

  args.outputs.primitives << {x:0, y:0, w:720, h:1280, r:0, g:0, b:0}.solid!
  draw_grid args
end
