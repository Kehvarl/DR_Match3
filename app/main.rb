def init args
  args.state.grid = {}
  args.state.grid_w = 9
  args.state.grid_h = 9
  args.state.tile_size = 80
  args.state.starting_height = 560
  load_grid args
end

def load_grid args
  args.state.grid = {}
  tile_size = args.state.tile_size
  sy = args.state.starting_height
  (0...args.state.grid_h).each do |y|
    (0...args.state.grid_w).each do |x|
      args.state.grid[[x,y]] = {x:x*tile_size, y:sy+y*tile_size, w:tile_size, h:tile_size, path:'sprites/square/green.png'}.sprite!
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

  draw_grid args
  args.outputs.primitives << {x:0, y:0, w:720, h:560, r:0, g:0, b:0}.solid!
end
