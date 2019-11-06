class MapsController < ApplicationController
  before_action :set_map, only: [:show, :edit, :update, :destroy]

  # GET /maps
  # GET /maps.json
  def index
    @map_bounds = [20, 20]
    @current_position = [15,15]
    @map = []
    create_initial_map
    generate_map
  end

  private

  def generate_map
    generate_room(@current_position)
    @current_position = make_door(@current_position)
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

  def make_door(position)
    door_possibilities = [[4, 2], [2, 0], [0,2], [2, 4]]

    door_possibilities.delete([0,2]) if @current_position.first == 0
    door_possibilities.delete([4,2]) if @current_position.first == @map_bounds.first - 5
    door_possibilities.delete([2,0]) if @current_position.last == 0
    door_possibilities.delete([2, 4])if @current_position.last == @map_bounds.last - 5

    random = door_possibilities.sample
    door = [position.first + random.first, position.last + random.last]
    @map[door.first][door.last] = 'door'
    door
  end

  def generate_room(location)
    3.times do |index|
      3.times do |index2|
        @map[location[0] + index + 1][location[1] + index2 + 1] = 'room'
        puts [index, index2].to_s
      end
    end
  end
end
