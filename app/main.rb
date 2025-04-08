require '/app/tile.rb'
require '/app/game.rb'

def init args
    args.state.game = Grid.new(args)
end

def tick args
    if args.tick_count == 0
        init args
    end

    args.state.game.tick()


    args.outputs.primitives << {x:0, y:0, w:720, h:1280, r:0, g:0, b:0}.solid!
    args.outputs.primitives << args.state.game.render()
end
