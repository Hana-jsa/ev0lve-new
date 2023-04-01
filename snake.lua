main_font = render.create_font_gdi("seguisb", 25,4);

function dump(o, indent)
    indent = indent or ""
    if type(o) == 'table' then
       local s = "{\n"
       local i = 1
       for k,v in pairs(o) do
          if i > 1 then
             s = s .. ",\n"
          end
          if type(k) == "string" then
             k = '"' .. k .. '"'
          end
          s = s .. indent .. "   [" .. k .. "] = " .. dump(v, indent .. "   ")
          i = i + 1
       end
       s = s .. "\n" .. indent .. "}"
       return s
    else
       return tostring(o)
    end
 end

local config = {
    board_size = 500, -- base size
    board_x = 670, -- base x
    board_y = 350, -- base y
    score = 0, -- players score
    drag = { -- info about dragging
        active = false,
        difference = { -- stores delta used to do proper dragging
            x = 0, -- x delta
            y = 0 -- y delta
        }
    }
}

local snake = {
    color = render.color(0, 255, 0, 205), -- color of the snake
    size = 5, -- snakes base size
    pos = { { 25, 25 } }, -- all positions of the snake
    delay = 0, -- delay on snake movements
    curr_time = 0, -- curr time for snake
    old_curr_time = 0 -- last curr time
}

local food = {
    max = 5, -- max amount of food
    color = render.color(255, 0, 0, 205), -- color of the food
    pos = { }, -- all positions of food
    delay = 0, -- delay on food timer
    curr_time = 0, -- curr time for food
    old_curr_time = 0 -- last currtime
}

local keys = {
    mouse1 = 0x00, -- mouse 1 button
    left = 0x25, -- left arrow key
    up = 0x26, -- up arrow key
    right = 0x27, -- right arrow key
    down = 0x28 -- down arrow key
}

local snake_ui = gui.checkbox('SnakeUI', 'scripts.elements_a', 'Show snake ui - bind me')

function point_inside_region(mx, my, x, y, w, h)
    -- check if a point is inside a certain boundary
    return mx >= x and my >= y and mx <= x + w and my <= y + h
end

function normalize_position(pos)
    -- if x position is lower than 0, reset position to the right
    if pos[1] < 0 then
      pos[1] = pos[1] + config.board_size / 10
    end
    
    -- same with y position, reset position to the bottom
    if pos[2] < 0 then
      pos[2] = pos[2] + config.board_size / 10
    end
    
    -- if x position is lower than the max tile position, reset position to the left
    -- same with y position, reset position to the top
    pos[1] = pos[1] % (config.board_size / 10)
    pos[2] = pos[2] % (config.board_size / 10)
    
    -- return normalized position
    return pos
end

function render.food()
    -- store time
    food.curr_time = global_vars.curtime
    food.delay = 3 + math.floor(math.random() * 6)

    -- check if we should update here
    if food.curr_time > food.delay + food.old_curr_time then
        -- save current time
        food.old_curr_time = food.curr_time

        -- check if we haven't reached the maximum amount of cherries
        if #food.pos < food.max then
            -- generate a random position for this cherry
            local pos = {math.floor(math.random() * (config.board_size / 10)), math.floor(math.random() * (config.board_size / 10))}

            -- add a new cherry to the board
            table.insert(food.pos, pos)
        end
    end

    -- loop through every cherry
    for i = 1, #food.pos do
        -- render cherry
        render.rect_filled(config.board_x + 1 + (food.pos[i][1] * 10), config.board_y + 1 + (food.pos[i][2] * 10), config.board_x + 1 + (food.pos[i][1] * 10) + 10, config.board_y + 1 + (food.pos[i][2] * 10) + 10, food.color)
    end
end

render.game_board = function()
    -- if we're not pressing mouse1, disable dragging
    if not input.is_mouse_down(keys.mouse1) then
        config.drag.active = false
    end

    -- get our cursor position
    local mx, my = input.get_cursor_pos()

    -- check if we're dragging the window
    if input.is_mouse_down(keys.mouse1) and point_inside_region(mx,my, config.board_x, config.board_y - 40, config.board_size, 35) or config.drag.active then
        -- we're now dragging!
        config.drag.active = true

        -- update the board's position
        config.board_x = mx - config.drag.difference.x
        config.board_y = my - config.drag.difference.y
    else
        -- update the deltas
        config.drag.difference.x = mx - config.board_x
        config.drag.difference.y = my - config.board_y
    end

    -- render the game board
    render.rect(config.board_x, config.board_y, config.board_x + (config.board_size + 1), config.board_y + (config.board_size +1), render.color(255,255,255,255), 1)
    render.rect_filled(config.board_x + 1, config.board_y + 1, config.board_x + (config.board_size - 1), config.board_y + (config.board_size - 1), render.color(25,25,25,255))
end

function render.status_bar(font)
    -- rendering the bar for text to be displayed on
    render.rect(config.board_x, config.board_y - 40, config.board_x + (config.board_size + 1), config.board_y - 40 + 35, render.color(255,255,255,255), 1)
    render.rect_filled(config.board_x + 1, config.board_y - 39, config.board_x + (config.board_size - 1), config.board_y - 39 + 33, render.color(25,25,25,255))

    -- rendering the score text
    render.text(font, config.board_x + 5, config.board_y - 35, "Score: "..tostring(config.score), render.color(235,235,235,205), 0, 0, 0)

    -- rendering the title
    render.text(font, config.board_x + config.board_size / 2, config.board_y - 35, "Snake", render.color(235,235,235,205), 0, 0, 0)
end

render.snake = function()
    -- store time
    snake.curr_time = global_vars.curtime
    snake.delay = 0.1

    -- check if we should update here
    if snake.curr_time > snake.delay + snake.old_curr_time then
        -- save current time
        snake.old_curr_time = snake.curr_time

        -- check if we're moving
        if inputs.left or inputs.up or inputs.right or inputs.down then
            -- get the first snake tile, that is, the head of the snake
            local pos = snake.pos[1]

            -- get how much we'll move based on direction
            local x_increment = inputs.left and -1 or inputs.right and 1 or 0
            local y_increment = inputs.up and -1 or inputs.down and 1 or 0

            -- calculate where we'll be in the next tick
            local end_pos = {
                pos[1] + x_increment % 50,
                pos[2] + y_increment % 50
            }

            -- normalize the position to make sure we don't go out of bounds
            -- and push it to the front of the position array
            table.insert(snake.pos, 1, normalize_position(end_pos))

            -- get the next position
            pos = end_pos

            -- loop through every food/cherry position
            for f = 1, #food.pos do
                -- get current food/cherry position
                local food_pos = food.pos[f]

                -- check if we're colliding with a food/cherry
                if food_pos[1] == pos[1] and food_pos[2] == pos[2] then
                    -- if so, increment score and delete this food/cherry
                    snake.size = snake.size + 1
                    config.score = config.score + 1

                    table.remove(food.pos, f)
                    break
                    -- when snake hits the food we
                    -- Increase the size of snake by 1
                    -- Increase the score by 1
                    -- And then delete the food
                end
            end

            -- loop through every snake position
            -- skip the first one because that's our head
            for s = 2, #snake.pos do
                -- get current snake position
                snake_pos = snake.pos[s]

                -- check if we're colliding with one of our positions
                if snake_pos[1] == pos[1] and snake_pos[2] == pos[2] then
                    -- reset everything
                    
                   -- snake.pos = {{25, 25}}
                    for i = 1, #snake.pos do 
                        snake.pos[i][1] = 25
                        snake.pos[i][2] = 25
                    end

                    snake.size = 5
                    
                    food.pos = {}

                    config.score = 0

                    inputs.left = false
                    inputs.up = false
                    inputs.right = false
                    inputs.down = false
                end
            end
            
            --print(snake.size)
            -- check if we have more positions than the size of our snake
            -- this means we're exceeding the maximum amount of positions
            if #snake.pos > snake.size + 1 then
                print("Size "..snake.size)
                print("posAmt "..#snake.pos)
                -- delete the last position
                while #snake.pos > snake.size do
                    table.remove(snake.pos)
                end
            end
        end
    end

    -- loop through every position
    for i = 1, #snake.pos do
        -- render snake
        --print(type(snake.pos[i]))
        local x = config.board_x + 1 + (snake.pos[i][1] * 10)
        local y = config.board_y + 1 + (snake.pos[i][2] * 10)
        local x2 = x + 9
        local y2 = y + 9

        render.rect_filled(
            x,
            y,
            x2,
            y2,
            snake.color
        )        
    end
end

inputs = {
    left = false, up = false, right = false, down = fasle
}

input.movement = function()
    if input.is_key_down(keys.left) then
        inputs = {
            left = true, up = false, right = false, down = false
        }
    end

    if input.is_key_down(keys.up) then
        inputs = {
            left = false, up = true, right = false, down = false
        }
    end

    if input.is_key_down(keys.right) then
        inputs = {
            left = false, up = false, right = true, down = false
        }
    end

    if input.is_key_down(keys.down) then
        inputs = {
            left = false, up = false, right = false, down = true
        }
    end

    if not snake_ui:get_value() then
        inputs = {
            left = false, up = false, right = false, down = false
        }
    end

    return inputs
end 

function on_paint()
    if snake_ui:get_value() then 
        input.movement()

        render.game_board();
        render.status_bar(main_font);

        render.snake();
        render.food();
    end
end