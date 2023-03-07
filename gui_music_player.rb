require 'rubygems'
require 'gosu'
require "json"

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)

module ZOrder
  BACKGROUND, UI = *0..1
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']

class ArtWork
	attr_accessor :bmp, :pos, :scale, :width, :height

	def initialize (file, pos, scale)
		@bmp = Gosu::Image.new(file)
		@width = Gosu::Image.new(file).width()
		@height = Gosu::Image.new(file).height()
		@pos = pos
		@scale = scale
	end
end

class Album
	attr_accessor :id, :title, :artist, :artwork, :genre, :tracks

	def initialize(id ,title, artist, artwork, genre, tracks)
		@id = id
		@title = title
		@artist = artist
		@artwork = artwork
		@genre = genre
		@tracks = tracks
	end
end

class MusicPlayerMain < Gosu::Window
	def initialize
		super 800,600
		@font = Gosu::Font.new(30)
		@current_album = -1
		@current_track = -1
		@status = ""
		self.caption = "Music Player"
		file = File.open("albums.json")
		data = JSON.load(file)
		file.close()
		@albums = Array.new()
		count = 0
		for album in data["albums"]
			artwork = ArtWork.new(album["image_location"], album["image_position"], album["image_scale"])
			@albums << Album.new(count ,album["title"], album["artist"], artwork, GENRE_NAMES[album["genre"]], album["tracks"])
			count += 1
		end
	end

	def draw_background
		draw_quad(0,0, TOP_COLOR, 0, 600, TOP_COLOR, 800, 0, BOTTOM_COLOR, 800, 600, BOTTOM_COLOR, z = ZOrder::BACKGROUND)
	end

	def draw_albums
		for album in @albums
			album.artwork.bmp.draw(album.artwork.pos[0],album.artwork.pos[1], ZOrder::UI, album.artwork.scale, album.artwork.scale)
		end
	end

	def draw_icons
		Gosu::Image.new("buttons/previous-button.png").draw(10,400,ZOrder::UI,0.1,0.1) #previous button
		Gosu::Image.new("buttons/play-and-pause-button.png").draw(160,400,ZOrder::UI,0.1,0.1) # play or pause button
		Gosu::Image.new("buttons/forward-button.png").draw(310,400,ZOrder::UI,0.1,0.1) #next button
	end

	def display_track(tracks, marked = -1)
		ypos = 50
		for track in tracks
			if track["id"] == marked + 1
				@font.draw("*", 420, ypos, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
			end
			@font.draw(track["title"], 450, ypos, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
			ypos += 40
		end
	end

	def draw()
		draw_background()
		draw_albums()
		draw_icons()
		if @current_album != -1
			display_track(@albums[@current_album].tracks, @current_track)
		end
	end

	def needs_cursor?; true; end

	def area_clicked()
		# area click for each album
		for album in @albums
			pos_x = album.artwork.pos[0]
			pos_y = album.artwork.pos[1]
	
			if (mouse_x > pos_x && mouse_x < pos_x + album.artwork.scale * album.artwork.width) && 
				(mouse_y > pos_y && mouse_y < pos_y + album.artwork.scale * album.artwork.height)
				@current_album = album.id
				@current_track = 0
				@status = "Play"
				playTrack(@current_album,@current_track)
			end
		end
		# area click for previous button
		if @current_album != -1
			# area click for each track
			track_id = 0
			while track_id < @albums[@current_album].tracks.length
				if (mouse_x > 420) && (mouse_y > 50 + 40 * track_id  && mouse_y < 50 + 40 * track_id + 30)
					@current_track = track_id
					playTrack(@current_album,@current_track)
				end
				track_id += 1
			end
			if (mouse_x > 10 && mouse_x < 60) && (mouse_y > 400 && mouse_y < 450)
				if @current_track == 0
					playTrack(@current_album, @current_track)
				else 
					@current_track -= 1
					playTrack(@current_album, @current_track)
				end
			end
			# area click for play or pause button
			if (mouse_x > 160 && mouse_x < 210) && (mouse_y > 400 && mouse_y < 450)
				if @song.playing?
					@song.pause
					@status = "Pause"
				else
					@song.play
					@status = "Play"
				end
			end
			# area click for next button
			if (mouse_x > 310 && mouse_x < 360) && (mouse_y > 400 && mouse_y < 450)
				if (@current_track == (@albums[@current_album].tracks.length - 1))
					@current_track = 0
					playTrack(@current_album, @current_track)
				else
					@current_track += 1
					playTrack(@current_album, @current_track)
				end
			end
		end
		
	end

	def playTrack(album_id, track_id)
		@song = Gosu::Song.new(@albums[album_id].tracks[track_id]["location"])
		@song.play(false)
	end

	def update
		if @song
			if !@song.playing? && @status == "Play"
				if @current_track < @albums[@current_album].tracks.length
					@current_track += 1
					playTrack(@current_album, @current_track)
				end
			end
		end
	end

	def button_down(id)
		case id
	    when Gosu::MsLeft
	    	area_clicked()
	    end
	end

end

MusicPlayerMain.new.show if __FILE__ == $0
