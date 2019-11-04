class MapsController < ApplicationController
  before_action :set_map, only: [:show, :edit, :update, :destroy]

  # GET /maps
  # GET /maps.json
  def index
    @invalid_chunks = []
    @bounds = [600, 800]
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
  # requirement: boxes need to be at least 10 px away from one another at both height and width
  # 0 - 500 -- x point is 50 so the box is 50 + 50 so the points are 50 - 100 add bounds so 40 - 110
  # 0 - 500 -- y point is 20 so the box is 20 + 50 so the points are 20 - 70 add bounds so 10 - 80
  # if the pair generated has an x value in the blocked off groups and a y value in the corresponding y blocks, reject it.
  def generate_random_valid_pair
    max_bounds = [@bounds[0]-50, @bounds[1]-50]
    random_pair = []
    valid = false

    if @invalid_chunks.empty?
      random_pair = [rand(max_bounds[0]), rand(max_bounds[1])]
      @invalid_chunks << random_pair
    else
      until valid do
        random_pair = [rand(max_bounds[0]), rand(max_bounds[1])]
        @invalid_chunks.each do |chunk|
          if random_pair[0] > chunk[0] - 60 && random_pair[0] < chunk[0] + 60
            if random_pair[1] > chunk[1] - 60 && random_pair[1] < chunk[1] + 60
              valid = false
              break
            end
          end
          valid = true
        end
      end
      @invalid_chunks << random_pair
    end
    random_pair
  end

  def generate_boxes
    # binding.pry
    boxes = []
    10.times do |index|
      # binding.pry
      valid_pair = generate_random_valid_pair
      boxes << {key: index, width: 50, height: 50, x: valid_pair[0], y: valid_pair[1]}
    end
    boxes
  end
end
