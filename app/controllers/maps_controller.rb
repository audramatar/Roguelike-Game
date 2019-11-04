class MapsController < ApplicationController
  before_action :set_map, only: [:show, :edit, :update, :destroy]

  # GET /maps
  # GET /maps.json
  def index
    @invalid_chunks = []
    @bounds = [1200, 800]
    @boxes = generate_boxes
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
      random_box = { x: rand(max_bounds[0]), y: rand(max_bounds[1]), height: box_height, width: box_width }
      @invalid_chunks << random_box
    else
      until valid do
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
          valid = true
        end
      end
      @invalid_chunks << random_box
    end
    random_box
  end

  def generate_boxes
    boxes = []
    10.times do |index|
      height = rand(50..100)
      width = rand(50..100)
      valid_box = generate_random_valid_pair([width, height])
      boxes << {key: index, width: width, height: height, x: valid_box[:x], y: valid_box[:y]}
    end
    boxes
  end
end
