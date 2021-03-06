# -*- coding: utf-8 -*-
# Copyright 2008-2010 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of VCC (Virtual Conference Center).
#
# VCC is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VCC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with VCC.  If not, see <http://www.gnu.org/licenses/>.

class HomesController < ApplicationController

  before_filter :authentication_required
  respond_to :json, :only => [:user_rooms]
  respond_to :html, :except => [:user_rooms]

  def index
  end

  def show
    @server = BigbluebuttonServer.first
    @room = current_user.bigbluebutton_room
    @recordings = @room.recordings.published().order("end_time DESC").first(3)
    begin
      @room.fetch_meeting_info
    rescue Exception
    end

    if params[:update_rooms]
      render :partial => 'homes/rooms'
      return
    end

    unless current_user.spaces.empty?
      @events_of_user = Event.in(current_user.spaces).all(:order => "start_date ASC")
    end

    @update_act = params[:contents] ? true : false

    @contents_per_page = params[:per_page] || 5
    @contents = params[:contents].present? ? params[:contents].split(",").map(&:to_sym) : Space.contents
    @all_contents = ActiveRecord::Content.paginate({ :page => params[:page], :per_page => @contents_per_page.to_i, :order => 'updated_at DESC' },
                                                   { :containers => current_user.spaces, :contents => @contents} )

    #let's get the inbox for the user
    @private_messages = PrivateMessage.find(:all, :conditions => {:deleted_by_receiver => false, :receiver_id => current_user.id},:order => "created_at DESC", :limit => 3)
  end

  # renders a json with the webconference rooms accessible to the current user
  # response example:
  #
  # [
  #   { "bigbluebutton_room":
  #     { "name":"Admins Room", "join_path":"/bigbluebutton/servers/default-server/rooms/admins-room/join?mobile=1",
  #       "owner":{ "type":"User", "id":"1" } }
  #   }
  # ]
  #
  # The attribute "owner" will follow one of the examples below:
  # "owner":null
  # "owner":{ "type":"User", "id":1 }
  # "owner":{ "type":"Space", "id":1, "name":"Space's name", "public":true }
  #
  def user_rooms
    array = current_user.accessible_rooms || []
    mapped_array = array.map{ |r|
      link = join_bigbluebutton_room_path(r, :mobile => '1')
      { :bigbluebutton_room => { :name => r.name, :join_path => link, :owner => owner_hash(r.owner) } }
    }
    render :json => mapped_array
  end

  def recordings
    @room = current_user.bigbluebutton_room
    @recordings = @room.recordings.published().order("end_time DESC")
    if params[:limit]
      @recordings = @recordings.first(params[:limit].to_i)
    end
    if params[:partial]
      render "recordings", :layout => false
    else
      render "recordings", :layout => "application_without_sidebar"
    end
  end

  private

  def owner_hash(owner)
    if owner.nil?
      nil
    else
      hash = { :type => owner.class.name, :id => owner.id }

      if owner.instance_of?(Space)
        space_hash = { :name => owner.name, :public => owner.public?, :member => owner.actors.include?(current_user) }
        hash.merge!(space_hash)
      end

      hash
    end
  end

end
