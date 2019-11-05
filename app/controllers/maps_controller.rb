class MapsController < ApplicationController
  before_action :set_map, only: [:show, :edit, :update, :destroy]

  # GET /maps
  # GET /maps.json
  def index
    @generated_boxes = []
    @bounds = [1200, 800]
    # @bounds = [300, 300]
    @path_points = []
    @path_points_string = ''
    @path_line_arrays = []
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

    if @generated_boxes.empty?
      until valid do
        random_box = { x: rand(max_bounds[0]), y: rand(max_bounds[1]), height: box_height, width: box_width }
        if within_bounds?(random_box[:x], random_box[:y], room_size[0], room_size[1])
          valid = true
        end
      end
      @generated_boxes << random_box
    else
      until valid do
        valid = false
        random_box = { x: rand(max_bounds[0]), y: rand(max_bounds[1]), height: box_height, width: box_width }
        @generated_boxes.each do |chunk|
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
        valid = false if does_box_collide_with_path?(random_box)
      end
      @generated_boxes << random_box
    end
    random_box
  end

  def does_box_collide_with_path?(box)
    # return true if the box collides
    all_edge_points_in_box(box).each do |point|
      @path_line_arrays.each do |path_array|
        return true if path_array.include?(point)
      end
    end
    false
  end

  def all_edge_points_in_box(box)
    edge_points = []
    x =  (box[:x]..(box[:x] + box[:width])).to_a
    y =  (box[:y]..(box[:y] + box[:height])).to_a
    edge_points << x.map{|point| [point, box[:y]]}
    edge_points << x.map{|point| [point, (box[:y] + box[:height])]}
    edge_points << y.map{|point| [box[:x], point]}
    edge_points << y.map{|point| [(box[:x] + box[:width]), point]}
    edge_points.flatten
  end

  def add_new_path_point(point)
    unless @path_points.empty?
      prev_point = @path_points.last
      direction = which_direction(prev_point, point)
      case direction
      when :left
        # new x value is < old x value
        @path_line_arrays << (point[0]..prev_point[0]).to_a.map{|value| [value, point[1]]}
      when :right
        # new x value is > old x value
        @path_line_arrays << (prev_point[0]..point[0]).to_a.map{|value| [value, point[1]]}
      when :up
        # new y value > old y value
        @path_line_arrays << (prev_point[1]..point[1]).to_a.map{|value| [point[0], value]}
      when :down
        # new y value < old y value
        @path_line_arrays << (point[1]..prev_point[1]).to_a.map{|value| [point[0], value]}
      end

      @path_points << point
    end
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
    add_new_path_point(exit_points(prev_box[:x], prev_box[:y], prev_box[:width], prev_box[:height])[first_direction])
    
    new_x = new_box[:x] + new_box[:width]/2
    new_y = new_box[:y] + new_box[:height]/2

    if first_direction == :right || first_direction == :left
      avoid_collision(@path_points.last, [new_x, @path_points.last[1]], new_box)
      
      avoid_collision(@path_points.last, [new_x, new_y], new_box)
    else
      avoid_collision(@path_points.last, [@path_points.last[0], new_y], new_box)
      
      avoid_collision(@path_points.last, [new_x, new_y], new_box)
    end

  end

  def check_for_room_collision(x_or_y, prev_point, new_point, new_box)
    # x_or_y stands for whether the line is moving on the x or y axis
    # If it's moving on the x axis, then find the stable y value and vice versa
    if x_or_y == :x
      x_values = prev_point[0] < new_point[0] ? (prev_point[0]..new_point[0]).to_a : (new_point[0]..prev_point[0]).to_a
    else
      y_values = prev_point[1] < new_point[1] ? (prev_point[1]..new_point[1]).to_a : (new_point[1]..prev_point[1]).to_a
    end

    colliding_boxes = []
    # it shouldn't be concerned with the last two boxes it connected to.
    # popped_data = @generated_boxes.pop
    # @generated_boxes << new_box
    @boxes.each do |box|
      if x_or_y == :x
        # if any y values on the box match the y value of our new horizontal line
        if (box[:y]..(box[:y] + box[:height])).to_a.include?(new_point[1])
          # and if either of the polar points of our x values match any of the x values in our horizontal line
          if x_values.include?(box[:x]) || x_values.include?(box[:x] + box[:width])
            # we've collided!
            colliding_boxes << box
          end
        end
      else
        if (box[:x]..(box[:x] + box[:width])).to_a.include?(new_point[0])
          if y_values.include?(box[:y]) || y_values.include?(box[:y] + box[:height])
            # we've collided!
            colliding_boxes << box
          end
        end
      end
    end
    # @generated_boxes.pop
    # @generated_boxes << popped_data
    # @generated_boxes << new_box
    colliding_boxes
  end

  def avoid_collision(prev_point, new_point, new_box)
    # if the line is moving to the right and is going to collide with a box
    # find the box's left exit point. Then add a stop 5 pixels from the box.
    # Go up or down instead to meet the y value of the exit point. Then continue
    # into the box. Continue for 5 ( based on how many pixels min apart) pixels out
    # of the box directly across before returning to the y value of the
    # destination point. Then continue right until you reach the destination.
    exits = exit_points(new_box[:x], new_box[:y], new_box[:width], new_box[:height])
    case which_direction(prev_point, new_point)
    when :right
      # direction is for the exit that you're looking for. So it's opposite
      create_points_to_avoid_collision(:x, prev_point, exits[:right], :right, new_box)
      add_new_path_point(new_point)
    when :left
      create_points_to_avoid_collision(:x, prev_point, exits[:left], :right, new_box)
      add_new_path_point(new_point)
    when :up
      create_points_to_avoid_collision(:y, prev_point, exits[:up], :up, new_box)
      add_new_path_point(new_point)
    when :down
      create_points_to_avoid_collision(:y, prev_point, exits[:down], :up, new_box)
      add_new_path_point(new_point)
    end
  end

  def create_points_to_avoid_collision(x_or_y, prev_point, new_point, direction, new_box)
    
    boxes_in_the_way = check_for_room_collision(x_or_y, prev_point, new_point, new_box)
    if boxes_in_the_way.empty?
      # do nothing. Probably fix this.
    else
      if x_or_y == :x
        boxes_in_the_way.each do |box|
          touching = line_and_box_touching?(prev_point, box)
          if touching == :top
            add_new_path_point([prev_point[0], prev_point[1] + 5])
            # avoid_collision(@path_points.last, new_point, new_box)
          elsif touching == :bottom
            add_new_path_point([prev_point[0], prev_point[1] - 5])
            # avoid_collision(@path_points.last, new_point, new_box)
          end
          exit_needed = direction == :left ? :right : :left
          box_exit = exit_points(box[:x], box[:y], box[:width], box[:height])[exit_needed]
          # Stop before the box
          left_or_right = direction == :left ? 5 : -5
          add_new_path_point([box_exit[0] - left_or_right, prev_point[1]])
          # Go up/down to meet the exit's y value
          add_new_path_point([@path_points.last[0], box_exit[1]])
          # Enter via the exit point
          add_new_path_point(box_exit)
          # continue through the box and an additional 5 pixels
          if direction == :left
            add_new_path_point([box_exit[0] + box[:width], box_exit[1]])
          else
            add_new_path_point([box_exit[0] - box[:width], box_exit[1]])
          end
          # return to the y value of the new point
          add_new_path_point([@path_points.last[0], new_point[1]])
          # avoid_collision(@path_points.last, new_point, new_box)
        end
      else
        boxes_in_the_way.each do |box|
          touching = line_and_box_touching?(prev_point, box)
          if touching == :right
            add_new_path_point([prev_point[0] + 5, prev_point[1]])
            avoid_collision(@path_points.last, new_point, new_box)
          elsif touching == :left
            add_new_path_point([prev_point[0] - 5, prev_point[1]])
            avoid_collision(@path_points.last, new_point, new_box)
          else
            exit_needed = direction == :up ? :down : :up
            box_exit = exit_points(box[:x], box[:y], box[:width], box[:height])[exit_needed]
            # Stop before the box
            up_or_down = direction == :up ? 5 : -5
            add_new_path_point([prev_point[0], box_exit[1] - up_or_down])
            # Go right/left to meet the exit's y value
            add_new_path_point([box_exit[0], @path_points.last[1]])
            # Enter via the exit point
            add_new_path_point(box_exit)
            # continue through the box and an additional 5 pixels
            if direction == :up
              add_new_path_point([box_exit[0], box_exit[1] + box[:height] + 5])
            else
              add_new_path_point([box_exit[0], box_exit[1] - box[:height] - 5])
            end
            # return to the y value of the new point
            add_new_path_point([new_point[0], @path_points.last[1]])
            # avoid_collision(@path_points.last, new_point, new_box)
          end
        end
      end
      add_new_path_point(new_point)
    end
  end

  def line_and_box_touching?(prev_point, box)
    if prev_point[0] == box[:x]
      return :left
    elsif prev_point[0] == box[:x] + box[:width]
      return :right
    elsif prev_point[1] == box[:y]
      return :bottom
    elsif prev_point[1] == box[:y] + box[:height]
      return :top
    end
    false
  end

  # def get_side_values(start, distance)
  #   (start..(start + distance)).to_a
  # end

  def exit_points(x, y, width, height)
    { left: [x, y + height/2], right: [x + width, y + height/2], up: [x + width/2, y + height], down: [x + width/2, y] }
  end

  def which_direction(old_point, new_point)
    # positive if left, negative is right
    x_distance = old_point[0] - new_point[0]

    # positive is down, negative is up
    y_distance = old_point[1] - new_point[1]

    # if positive, x weight is more, negative y weight is more
    weight = x_distance.abs - y_distance.abs

    if weight.positive?
      x_distance.positive? ? :left : :right
    else
      y_distance.positive? ? :down : :up
    end
  end

  def format_path_points
    @path_points.each do |point|
      @path_points_string += "#{point[0]},#{point[1]} "
    end
  end

  def generate_boxes
    20.times do |index|
      # height = rand(50..100)
      # width = rand(50..100)
      height = 100
      width = 100
      valid_box = generate_random_valid_pair([width, height])
      new_box = {key: index, width: width, height: height, x: valid_box[:x], y: valid_box[:y]}
      update_path_points(new_box)
      
      @boxes << new_box
    end
  end
end
