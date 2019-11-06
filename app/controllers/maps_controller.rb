class MapsController < ApplicationController
  before_action :set_map, only: [:show, :edit, :update, :destroy]

  # GET /maps
  # GET /maps.json
  def index
    @map_bounds = [20, 20]
    @current_position = [0,0]
    @map = []
    @spots_around = [[-1, 0], [1, 0], [0, -1], [0, 1]]
    create_initial_map
    generate_map
  end

  private

  def generate_map
    @current_position = make_random_door(@current_position) if generate_first_room(@current_position)
    10.times {@current_position = make_hallway(@current_position)}
    generate_door(@current_position)
  end

  def create_initial_map
    @map_bounds.first.times do
      row = []
      @map_bounds.last.times do
        row.push('wall')
      end
      @map << row
    end
  end

  def make_random_door(position)
    door_possibilities = [[4, 2], [2, 0], [0,2], [2, 4]]

    door_possibilities.delete([0,2]) if position.first == 0
    door_possibilities.delete([4,2]) if position.first == @map_bounds.first - 5
    door_possibilities.delete([2,0]) if position.last == 0
    door_possibilities.delete([2, 4])if position.last == @map_bounds.last - 5

    random = door_possibilities.sample
    door = [position.first + random.first, position.last + random.last]
    @map[door.first][door.last] = 'door'
    door
  end

  def make_hallway(position)
    possible_directions = [
        [position[0] + 1, position[1]],
        [position[0] - 1, position[1]],
        [position[0], position[1] + 1],
        [position[0], position[1] - 1]
    ]
    bad_options = []
    possible_directions.each do |movement|
      new_spot = @map[movement[0]][movement[1]]

      if out_of_bounds?(movement)
        bad_options << movement
      elsif colliding?(new_spot)
        bad_options << movement
      elsif breaking_down_walls?(movement)
        bad_options << movement
      end

    end

    puts bad_options.to_s
    possible_directions.delete_if { |direction| bad_options.include?(direction) }

    return position if possible_directions.empty?
    new_location = possible_directions.sample
    puts possible_directions.to_s
    puts "chosen: " + new_location.to_s
    puts ""
    @map[new_location[0]][new_location[1]] = 'hall'
    new_location
  end

  def colliding?(object)
    return true if object == 'room'
    false
  end

  def out_of_bounds?(point)
    if point[0] == 0 ||
       point[0] == @map_bounds[0] - 1 ||
       point[1] == 0 ||
       point[1] == @map_bounds[1] - 1
      return true
    end
    false
  end

  def breaking_down_walls?(point)
    hall_touches = 0
    check_points = [
        [point[0] + 1, point[1]],
        [point[0] - 1, point[1]],
        [point[0], point[1] + 1],
        [point[0], point[1] - 1]
    ]
    check_points.each do |new_point|
      object = @map[new_point[0]][new_point[1]]
      current_square = @map[point[0]][point[1]]
      puts "current object: #{current_square}, checking object: #{object}"
      hall_touches += 1 if object == 'hall' && current_square != 'hall'
      puts "hall touches: #{hall_touches}"
      return true if object == 'room'
      return true if hall_touches >= 2
    end
    false
  rescue => e
    binding.pry
  end

  def generate_first_room(position)
    if can_build_room?(position)
      3.times do |index|
        3.times do |index2|
          @map[position[0] + index + 1][position[1] + index2 + 1] = 'room'
        end
      end
    end
  end

  def generate_room(start_tile)
    3.times do |index|
      @map[start_tile[0] + index][start_tile[1]] = 'room'
      @map[start_tile[0] + index][start_tile[1] + 1] = 'room'
      @map[start_tile[0] + index][start_tile[1] - 1] = 'room'
    end
  end

  def generate_door(position)
    locations = valid_door_location(position)
    if valid_door_location(position)
      location = locations.sample
      @map[location[:door_point][0]][location[:door_point][1]] = 'door'
      @current_position = [location[:door_point][0], location[:door_point][1]]
      generate_room(location[:possible_locations].sample)
    else
      false
    end
  end

  def valid_door_location(position)
    valid_locations = []
    @spots_around.each do |point|
      door_point = [position[0] + point[0], position[1] + point[1]]
      if @map[door_point[0]][door_point[1]] == 'wall'
        possible_directions = valid_directions(door_point)
        if possible_directions
          valid_locations << { door_point: door_point, possible_locations: possible_directions}
        end
      end
    end
    valid_locations
  end

  # FINISH THISSSSS
  def valid_directions(door_point)
    # go up one square from the door and check the two squares to the left and the two squares to the right.
    # If all of them are walls, then take the far x axis edge ( farthest on the right and farthest on the left)
    # and check if the next four points to make sure each of them are walls. If they are, then check
    # the top three squares. If those are also walls, then it's a valid space.
    #
    valid_starts = []
    valid_starts << [door_point[0], door_point[1] + 1] unless start_invalid?(:y, 1, door_point)
    valid_starts << [door_point[0], door_point[1] - 1] unless start_invalid?(:y, -1, door_point)
    valid_starts << [door_point[0] + 1, door_point[1]] unless start_invalid?(:x, 1, door_point)
    valid_starts << [door_point[0] - 1, door_point[1]] unless start_invalid?(:x, -1, door_point)

    return false if valid_starts.empty?
    valid_starts
  end

  def can_build_room?(position)
    return false if position.first > @map_bounds[0] -5 || position.last > @map_bounds[1] -5
    true
  end

  def start_invalid?(x_or_y, positive_or_negative, door_point)
    get_points_to_check(x_or_y, positive_or_negative, door_point).each do |point|
      if @map[point[0]][point[1]] != 'wall'
        return true
      end
    end
    false
  end

  # FINISH THIS!!!!!!
  def get_points_to_check(x_or_y, positive_or_negative, door_point)
    if x_or_y == :y
      [
          [door_point[0], door_point[1] + 1 * positive_or_negative ],
          [door_point[0] + 1, door_point[1] + 1 * positive_or_negative ],
          [door_point[0] + 2, door_point[1] + 1 * positive_or_negative ],
          [door_point[0] - 1, door_point[1] + 1 * positive_or_negative ],
          [door_point[0] - 2, door_point[1] + 1 * positive_or_negative ],
          [door_point[0] - 2, door_point[1] + 2 * positive_or_negative ],
          [door_point[0] - 2, door_point[1] + 3 * positive_or_negative ],
          [door_point[0] - 2, door_point[1] + 4 * positive_or_negative ],
          [door_point[0] - 2, door_point[1] + 5 * positive_or_negative ],
          [door_point[0] + 2, door_point[1] + 2 * positive_or_negative ],
          [door_point[0] + 2, door_point[1] + 3 * positive_or_negative ],
          [door_point[0] + 2, door_point[1] + 4 * positive_or_negative ],
          [door_point[0] + 2, door_point[1] + 5 * positive_or_negative ],
          [door_point[0] + 1, door_point[1] + 4 * positive_or_negative ],
          [door_point[0], door_point[1] + 3 * positive_or_negative ],
          [door_point[0] - 1, door_point[1] + 2 * positive_or_negative ]
      ]
    else
      [
          [door_point[0] + 1 * positive_or_negative, door_point[1] ],
          [door_point[0] + 1 * positive_or_negative, door_point[1] + 1 ],
          [door_point[0] + 1 * positive_or_negative, door_point[1] + 2 ],
          [door_point[0] + 1 * positive_or_negative, door_point[1] - 1 ],
          [door_point[0] + 1 * positive_or_negative, door_point[1] - 2 ],
          [door_point[0] + 2 * positive_or_negative, door_point[1] - 2 ],
          [door_point[0] + 3 * positive_or_negative, door_point[1] - 2 ],
          [door_point[0] + 4 * positive_or_negative, door_point[1] - 2 ],
          [door_point[0] + 5 * positive_or_negative, door_point[1] - 2 ],
          [door_point[0] + 2 * positive_or_negative, door_point[1] + 2 ],
          [door_point[0] + 3 * positive_or_negative, door_point[1] + 2 ],
          [door_point[0] + 4 * positive_or_negative, door_point[1] + 2 ],
          [door_point[0] + 5 * positive_or_negative, door_point[1] + 2 ],
          [door_point[0] + 4 * positive_or_negative, door_point[1] + 1 ],
          [door_point[0] + 3 * positive_or_negative, door_point[1] ],
          [door_point[0] + 2 * positive_or_negative, door_point[1] -1 ]
      ]
    end
  end
end
