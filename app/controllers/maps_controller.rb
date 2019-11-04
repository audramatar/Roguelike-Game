class MapsController < ApplicationController
  before_action :set_map, only: [:show, :edit, :update, :destroy]

  # GET /maps
  # GET /maps.json
  def index
    @invalid_chunks = []
    @bounds = [1200, 800]
    @path_points = []
    @path_points_string = ''
    @boxes = []
    generate_boxes
    format_path_points
  end

  # GET /maps/1
  # GET /maps/1.json
  def show
  end

  # GET /maps/new
  def new
    @map = Map.new
  end

  # GET /maps/1/edit
  def edit
  end

  # POST /maps
  # POST /maps.json
  def create
    @map = Map.new(map_params)

    respond_to do |format|
      if @map.save
        format.html { redirect_to @map, notice: 'Map was successfully created.' }
        format.json { render :show, status: :created, location: @map }
      else
        format.html { render :new }
        format.json { render json: @map.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /maps/1
  # PATCH/PUT /maps/1.json
  def update
    respond_to do |format|
      if @map.update(map_params)
        format.html { redirect_to @map, notice: 'Map was successfully updated.' }
        format.json { render :show, status: :ok, location: @map }
      else
        format.html { render :edit }
        format.json { render json: @map.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /maps/1
  # DELETE /maps/1.json
  def destroy
    @map.destroy
    respond_to do |format|
      format.html { redirect_to maps_url, notice: 'Map was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  def generate_random_valid_pair(room_size)
    max_bounds = [@bounds[0]-50, @bounds[1]-50]
    random_box = []
    valid = false
    box_width = room_size[0] + 20
    box_height = room_size[1] + 20

    if @invalid_chunks.empty?
      until valid do
        random_box = { x: rand(max_bounds[0]), y: rand(max_bounds[1]), height: box_height, width: box_width }
        if within_bounds?(random_box[:x], random_box[:y], room_size[0], room_size[1])
          valid = true
        end
      end
      @invalid_chunks << random_box
    else
      until valid do
        valid = false
        random_box = { x: rand(max_bounds[0]), y: rand(max_bounds[1]), height: box_height, width: box_width }
        @invalid_chunks.each do |chunk|
          width = chunk[:width] > box_width ? chunk[:width] : box_width
          height = chunk[:height] > box_height ? chunk[:height] : box_height
          if random_box[:x] > chunk[:x] - width && random_box[:x] < chunk[:x] + width
            if random_box[:y] > chunk[:y] - height && random_box[:y] < chunk[:y] + height
              valid = false
              break
            end
          end
          unless within_bounds?(random_box[:x], random_box[:y], room_size[0], room_size[1])
            valid = false
            break
          end
          valid = true
        end
      end
      @invalid_chunks << random_box
    end
    random_box
  end

  def within_bounds?(x, y, width, height)
    rightmost_point = x + width
    lower_point = y + height
    if rightmost_point > @bounds[0] || lower_point > @bounds[1]
      return false
    end
    true
  end

  def update_path_points(new_box)
    if @path_points.empty?
      @path_points = [[(new_box[:x] + new_box[:width]/2),  (new_box[:y] + new_box[:height]/2)]]
    else
      find_proper_path(@boxes.last, new_box)
    end
  end

  def find_proper_path(prev_box, new_box)
    first_direction = which_direction([prev_box[:x], prev_box[:y]], [new_box[:x], new_box[:y]])

    # The point where the line will exit the room
    @path_points << exit_points(prev_box[:x], prev_box[:y], prev_box[:width], prev_box[:height])[first_direction]

    new_x = new_box[:x] + new_box[:width]/2
    new_y = new_box[:y] + new_box[:height]/2

    if first_direction == :right || first_direction == :left
      @path_points << [new_x, @path_points.last[1]]
      @path_points << [new_x, new_y]
    else
      @path_points << [@path_points.last[0], new_y]
      @path_points << [new_x, new_y]
    end

  end

  def exit_points(x, y, width, height)
    { left: [x, y + height/2], right: [x + width, y + height/2], up: [x + width/2, y], down: [x + width/2, y + height ] }
  end

  def which_direction(old_point, new_point)
    # positive if left, negative is right
    x_distance = old_point[0] - new_point[0]

    # positive is up, negative is down
    y_distance = old_point[1] - new_point[1]

    # if positive, x weight is more, negative y weight is more
    weight = x_distance.abs - y_distance.abs

    if weight.positive?
      x_distance.positive? ? :left : :right
    else
      y_distance.positive? ? :up : :down
    end
  end

  def format_path_points
    @path_points.each do |point|
      @path_points_string += "#{point[0]},#{point[1]} "
    end
  end

  def generate_boxes
    8.times do |index|
      height = rand(50..100)
      width = rand(50..100)
      valid_box = generate_random_valid_pair([width, height])
      new_box = {key: index, width: width, height: height, x: valid_box[:x], y: valid_box[:y]}
      update_path_points(new_box)
      @boxes << new_box
    end
  end
end
