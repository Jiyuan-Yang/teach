class BroadcastsController < ApplicationController
  # todo: add permission control

  def index
    user_id = User.find_by(gitlab_id: current_user.id).id
    @broadcasts = Broadcast.where(:to_id => user_id)
      # render json: {test: 123, test2: 456}
  end

  def new
    @errors = []
    @broadcast = Broadcast.new
  end

  def create
    type = params[:type]
    content = params[:content]
    class_id = params[:class_id]
    user_id = params[:user_id]
    from_user_id = User.find_by(gitlab_id: current_user.id).id

    if type == 'all'
      get_all_id_list.each do |item|
        broadcast = Broadcast.new
        broadcast.from_id = from_user_id
        broadcast.to_id = item
        broadcast.content = content
        broadcast.save
      end
    elsif type == 'all_students'
      get_all_students_id_list.each do |item|
        broadcast = Broadcast.new
        broadcast.from_id = from_user_id
        broadcast.to_id = item
        broadcast.content = content
        broadcast.save
      end
    elsif type == 'all_teachers'
      get_all_teachers_id_list.each do |item|
        broadcast = Broadcast.new
        broadcast.from_id = from_user_id
        broadcast.to_id = item
        broadcast.content = content
        broadcast.save
      end
    elsif type == 'class'
      get_class_all_id_list(class_id).each do |item|
        broadcast = Broadcast.new
        broadcast.from_id = from_user_id
        broadcast.to_id = item
        broadcast.content = content
        broadcast.save
      end
    elsif type == 'user'
      broadcast = Broadcast.new
      broadcast.from_id = from_user_id
      broadcast.to_id = user_id
      broadcast.content = content
      broadcast.save
    else
      redirect_to(classrooms_path)
    end
    redirect_to(classrooms_path)
  end

  private

  def get_all_id_list
    res = []
    User.all.each do |user|
      res.append(user.id)
    end
    res
  end

  def get_all_students_id_list
    res = []
    User.where(:role => 'student').each do |user|
      res.append(user.id)
    end
    res
  end

  def get_all_teachers_id_list
    res = []
    User.where(:role => 'teacher').each do |user|
      res.append(user.id)
    end
    res
  end

  def get_class_all_id_list(classroom_id)
    res = []
    SelectClassroom.where(:classroom_id => classroom_id).each do |sc|
      res.append(sc.user_id)
    end
    res
  end
end
