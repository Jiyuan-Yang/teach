class AutoTestProjectsController < ApplicationController
  PERSONAL_HOMEWORK_PROJECT_NAME = "student_personal_homework_project_"

  @@project_type = 'personal'
  @@errors_save = []

  @@creating_private_personal_project = false
  @@total_students_num = 0
  @@private_personal_project_progress = 0

  def show
  end

  def new
    @errors = []
    if @@errors_save.size > 0
      @errors = @@errors_save
      @@errors_save = []
    end
    @classroom_id = params[:classroom_id]
    classroom = Classroom.find_by(id: @classroom_id)
    @classroom_name = groups_service.get_group(classroom.gitlab_group_id)['path']
    @type = params[:type]
    @@project_type = params[:type]
    if params[:type] == 'personal'
      @title = '创建个人项目'
      @projects_name = 'personal-projects'
      @auto_test_project = AutoTestProject.new('personal')
    elsif params[:type] == 'personal-batch'
      redirect_to batch_create_classroom_auto_test_projects_path classroom_id: params[:classroom_id]
    elsif params[:type] == 'pair'
      @title = '创建结对项目'
      @projects_name = 'pair-projects'
      @auto_test_project = AutoTestProject.new('pair')
    end
  end

  def create
    classroom = Classroom.find_by(id: params[:classroom_id])
    auto_test_project = classroom.auto_test_projects.new
    @auto_test_project = params[:auto_test_project]

    if @auto_test_project[:test_type] == 'personal'
      @auto_test_project['namespace_id'] = classroom.personal_project_subgroup_id
    else
      @auto_test_project['namespace_id'] = classroom.pair_project_subgroup_id
    end
    @auto_test_project['visibility'] = 'public'
    @auto_test_project['request_access_enabled'] = true
    project = projects_service.new_project(@auto_test_project)
    auto_test_project.gitlab_id = project['id']
    auto_test_project.test_type = @auto_test_project[:test_type]
    auto_test_project.save
    # classroom.users << owner
    redirect_to classroom_path(params[:classroom_id])
  rescue RestClient::BadRequest => e
    @errors = ['名称或地址包含非法字符或已被占用']
    @@errors_save = @errors
    # render 'new'
    redirect_to new_classroom_auto_test_project_path + '?type=' + @@project_type
  end

  def new_private_personal_project
    @classroom_id = params[:classroom_id]
    @errors = []
  end

  def create_private_personal_project
    @classroom = Classroom.find(params[:class_id])
    @classroom_students_query = SelectClassroom.where(:classroom_id => params[:class_id])
    @all_students_gitlab_id_in_class = []
    @classroom_students_query.each do |item|
      tmp = User.find(item.user_id)
      if tmp.role == 'student'
        @all_students_gitlab_id_in_class.append(tmp.gitlab_id)
      end
    end

    @users = groups_service.get_members @classroom.gitlab_group_id

    if params[:type] == 'class'
      @@creating_private_personal_project = true
      # @students = @users.find_all do |user|
      #   !@classroom.users.find_by(gitlab_id: user[:id], role: 'student').nil?
      # end
      @students = []
      @users.each do |item|
        if @all_students_gitlab_id_in_class.index(item['id'])
          @students.append(item)
        end
      end
      @@total_students_num = @students.length
      # puts('>>>>>>>>')
      # puts(@students)
      # puts(@students.length)
      # puts('>>>>>>>>')
      batch_create_student_private_project @students
      @@creating_private_personal_project = false
    else
      @student = @users.find_by gitlab_id: params[:user_id]
      create_student_private_project @student
    end
  end

  def get_personal_project_status
    return_list = {
      is_creating: @@creating_private_personal_project,
      # is_creating: true,
      progress: @@private_personal_project_progress
    }
    render json: return_list
  end

  def destroy
    @auto_test_project = AutoTestProject.find_by(gitlab_id: params[:id])
    @auto_test_project.destroy
    projects_service.delete_project params[:id]
    redirect_to classroom_path(params[:classroom_id])
  end

  def feedback
    respond_to do |format|
      format.json do
        feedback = params[:feedback]
        test_record = get_test_record
        test_record.feedback = feedback
        test_record.save
        render json: {status: 'success'}
      end
    end
  end

  def trigger
    respond_to do |format|
      format.json do
        test_record = get_test_record
        action = params[:trigger]
        if action == 'start'
          gitlab_username = test_record.user.username
          pipeline = create_pipeline test_record.project_id, gitlab_username
          test_record.pipeline_id = pipeline['id']
          test_record.save
        elsif action == 'cancel'
          cancel_pipeline test_record.project_id, test_record.pipeline_id
          test_record.pipeline_id = nil
          test_record.save
        end
        render json: {status: 'success'}
      end
    end
  end

  private

  # 一下两个方法都与gitlab通过API交互，所以需要先从gitlab中取出相应的字段值
  def batch_create_student_private_project(students)
    cnt = 0
    students.each do |student|
      puts('************')
      create_student_private_project student
      cnt += 1
      @@private_personal_project_progress = 100 * (cnt / @@total_students_num)
    end
  end

  def create_student_private_project(student)
    @auto_test_project = {}
    @auto_test_project['user_id'] = student['id']
    # @auto_test_project['name'] = PERSONAL_HOMEWORK_PROJECT_NAME
    @auto_test_project['name'] = PERSONAL_HOMEWORK_PROJECT_NAME + student['username']
    @auto_test_project['visibility'] = 'private'
    @auto_test_project['request_access_enabled'] = 'false'
    auto_test_project = @classroom.auto_test_projects.new
    puts('>>>>>>>>>>>>>')
    puts(student)
    puts(student['id'])
    puts(@auto_test_project)
    project = projects_service.new_project_for_user student['id'], @auto_test_project
    puts('>>>>>>>>>>>>>')
    auto_test_project.gitlab_id = project['id']
    auto_test_project.test_type = 'personal'
    auto_test_project.save
  end

  def create_pipeline(project_id, gitlab_username)
    pipeline = {
        ref: 'master',
        variables: [
            {
                # predefined CI 变量改为该项目 owner
                key: 'GITLAB_USER_LOGIN',
                value: gitlab_username
            }
        ]
    }
    admin_api_post "projects/#{project_id}/pipeline", pipeline
  end

  def cancel_pipeline(project_id, pipeline_id)
    if pipeline_id
      admin_api_post "projects/#{project_id}/pipelines/#{pipeline_id}/cancel", {}
      admin_api_delete "projects/#{project_id}/pipelines/#{pipeline_id}"
    end
  end

  def get_test_record
    auto_test_project = AutoTestProject.find(params[:id])
    auto_test_project.student_test_records.find(params[:test_record_id])
  end

  def projects_service
    ::ProjectsService.new current_user
  end

  def groups_service
    ::GroupsService.new current_user
  end
end
