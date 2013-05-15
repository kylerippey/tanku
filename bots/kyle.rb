class MyFirstBot < RTanque::Bot::Brain
  NAME = 'kyle'
  include RTanque::Bot::BrainHelper

  def tick!
    ## main logic goes here
    self.drive

    self.seek

    self.target

    self.destroy

    self.print_info
  end

  def drive
    command.speed = 100
    rotate_tank
  end

  def seek
    if self.sensors.radar.count > 0
      command.radar_heading = self.sensors.radar.first.heading
    else
      rotate_radar(3)
      command.turret_heading = RTanque::Heading.new_from_degrees(self.radar_degrees)
    end
  end

  def target
    if self.sensors.radar.count > 0
      command.turret_heading = self.sensors.radar.first.heading
    end
  end

  def destroy
    #self.command.fire_power = 0.1
    #self.command.fire if self.sensors.gun_energy > 9
    #self.command.fire_power = (rand(20) == 1 ? 5.0 : 1.0)
    self.command.fire if self.sensors.radar.count > 0 && self.sensors.gun_energy.to_f > 9.5
  end

  def print_info
    puts "Radar Degrees: #{self.radar_degrees}"
    puts "Turret Degrees: #{self.turret_degrees}"
    puts "Gun Energy: #{self.sensors.gun_energy}"
    puts ""
  end

  def rotate_radar(rotation=1)
    self.radar_degrees = self.radar_degrees + rotation
    command.radar_heading = RTanque::Heading.new_from_degrees(self.radar_degrees)
  end

  def rotate_tank(rotation=1)
    self.tank_degrees = self.tank_degrees + rotation
    command.heading = RTanque::Heading.new_from_degrees(self.tank_degrees)
  end

  def tank_degrees
    @tank_degrees ||= 0
  end

  def tank_degrees=(value)
    value -= 360 if value > 360
    @tank_degrees = value
  end

  def radar_degrees
    @radar_degrees ||= 0
  end

  def radar_degrees=(value)
    value -= 360 if value > 360
    @radar_degrees = value
  end

  def rotate_turret(rotation=1)
    self.turret_degrees = self.turret_degrees + rotation
    command.turret_heading = RTanque::Heading.new_from_degrees(self.turret_degrees)
  end

  def turret_degrees
    @turret_degrees ||= 0
  end

  def turret_degrees=(value)
    value -= 360 if value > 360
    @turret_degrees = value
  end
end
