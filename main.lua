lick = require "lick"
lick.reset = true -- reload the love.load everytime you save
local reader = require("png")
local data = reader('./maze.png')
local grid = {}

local neighbours = {{-1, -1}, {0, -1}, {1, -1}, {-1, 0}, {1, 0}, {-1, 1}, {0, 1}, {1, 1}}
local ortho_neighbours = {{-1, 0}, {0, -1}, {1, 0}, {0, 1}}
local particle = love.graphics.newImage("particle.png")

local function get_neighbours(x, y, straight)
	local tbl = {}
	for _, xy in ipairs(straight and ortho_neighbours or neighbours) do
		local x = xy[1] + x
		local y = xy[2] + y

		local found = grid[y] and grid[y][x]
		if found then
			table.insert(tbl, found)
		end
	end
	return tbl
end



local function normalize_vector(x, y)
	local length = math.sqrt(x * x + y * y)
	if length == 0 then
		return 0, 0
	end
	return x / length, y / length
end

function love.load()
    love.window.setMode(1500, 1500, {resizable=true, vsync=true, minwidth=400, minheight=300})
  

	local w = data.width
	local h = data.height

	local stop
	
	for y = 1, h do
		grid[y] = grid[y] or {}
		for x = 1, w do
			local state = {
				x = x,
				y = y,
				wall = data.pixels[y][x].R == 0 and data.pixels[y][x].G == 0 and data.pixels[y][x].B == 0,
			}

			if data.pixels[y][x].R == 0 and data.pixels[y][x].G == 255 and data.pixels[y][x].B == 0 then
				stop = state
				stop.goal = true
			end

			grid[y][x] = state
		end
	end

	stop.distance = 0

	local to_visit = {stop}

	for _, node in ipairs(to_visit) do
		if node.wall then 
			node.distance = 100
			node.visited = true
		else
			local neighbours = get_neighbours(node.x, node.y, true)
			for _, n in ipairs(neighbours) do
				if not n.visited and not n.wall then
					n.visited = true
					n.distance = node.distance + 1
					table.insert(to_visit, n)
				end
			end
		end

	end

	for y = 1, #grid do
		for x = 1, #grid[y] do
			local center = grid[y][x]
			if not center.wall then
				if true then
					local neighbours = get_neighbours(center.x, center.y)
					
					local x = 0
					local y = 0
					
					for _, n in ipairs(neighbours) do
						if n.distance then
							local xx,yy = n.x - center.x, n.y - center.y
							local dist = center.distance - n.distance
							x = x + xx * dist
							y = y + yy * dist
						end
					end

					local xx,yy = normalize_vector(x, y)

					center.direction = {
						x = xx,
						y = yy,
					}

				end
				if false then
					local neighbours = get_neighbours(center.x, center.y)

					local found
					local min_dist = 0
					for _, n in ipairs(neighbours) do
						local dist = n.distance - center.distance

						if dist < min_dist then
							found = n
							min_dist = dist
						end
					end

					if found then
						center.direction = {
							x = found.x - center.x,
							y = found.y - center.y,
						}
					end
				end
			end
		end
	end
end

local function simulate(grid, pass)
	for y = 1, #grid do
		for x = 1, #grid[y] do
			local state = grid[y][x]
			
			for yy = y - 1, y + 1 do
				for xx = x - 1, x + 1 do
					if xx ~= x or yy ~= y then
						local neighbour = grid[yy] and grid[yy][xx]
						if neighbour and not neighbour.wall then
							pass(state, neighbour)
						end
					end
				end
			end
		end
	end
end

function love.graphics.arrow(x1, y1, x2, y2, arrlen, angle)
	love.graphics.line(x1, y1, x2, y2)
	local a = math.atan2(y1 - y2, x1 - x2)
	love.graphics.line(x2, y2, x2 + arrlen * math.cos(a + angle), y2 + arrlen * math.sin(a + angle))
	love.graphics.line(x2, y2, x2 + arrlen * math.cos(a - angle), y2 + arrlen * math.sin(a - angle))
end
local particles = {}
local size = 30
function love.draw()

	for y = 1, #grid do
		for x = 1, #grid[y] do
			local state = grid[y][x]

			if state.wall then
				love.graphics.setColor(1, 1, 1)
			elseif state.goal then
				love.graphics.setColor(0, 1, 0)
			else
				love.graphics.setColor(1, 0, 0, state.distance and 10/state.distance or 1)
			end
			
			local px = (x - 1) * size
			local py = (y - 1) * size
			
			love.graphics.rectangle('fill', px, py, size, size)

			love.graphics.setColor(0.5, 0.5, 0.5)

			local s = ""--state.x .. "," .. state.y

			if state.distance then
				--s = s .. "\n" .. tostring(state.distance)			
				--love.graphics.setColor(1, 0.15, 0.15)
			end

			love.graphics.print(s, px, py, 0, 1, 1)
			if state.direction then
				love.graphics.arrow(px + size / 2, py + size / 2, px + size / 2 + state.direction.x * size / 2, py + size / 2 + state.direction.y * size / 2, size / 8, math.pi / 4)
			end
		end
	end

	for _, particle in ipairs(particles) do

		love.graphics.setColor(particle.color)
		local px = particle.px * size
		local py = particle.py * size
		love.graphics.circle('fill', px, py, particle.size)


	end

end

function love.update(dt)
	

	for i = #particles, 1, -1 do
		local particle = particles[i]

		local x = math.ceil(particle.px)
		local y = math.ceil(particle.py)
		local cell = grid[y] and grid[y][x]
		if cell then
		

			if cell.wall then
				local wall_x = (cell.x-1) * size
				local wall_y = (cell.y-1) * size

				local dx = particle.px - wall_x
				local dy = particle.py - wall_y
				
			else
				particle.vx = (cell.direction.x - particle.vx) * dt
				particle.vy = (cell.direction.y - particle.vy) * dt
			end

			particle.px = particle.px + particle.vx
			particle.py = particle.py + particle.vy 

			particle.size = particle.size - 1 * dt
		end

		if particle.size < 0 then
			table.remove(particles, i)
		end
	end
	

	for i = 1, 10 do
		--if #particles > 0 then break end

		local x = math.random(1, #grid)
		local y = math.random(1, #grid[1])

		local cell = grid[y] and grid[y][x]
		if not cell or cell.wall then
			return
		end

		table.insert(particles, {
			x = x,
			y = y,
			px = x,
			py = y,
			vx = 0,
			vy = 0,
			size = (math.random() + 1) * 5,
			color = {
				math.random(),
				math.random(),
				math.random(),
			},
		})

	end
end
