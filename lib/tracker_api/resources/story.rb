module TrackerApi
  module Resources
    class Story
      include Shared::Base

      attribute :client

      attribute :accepted_at, DateTime
      attribute :after_id, Integer
      attribute :before_id, Integer
      attribute :comment_ids, [Integer]
      attribute :comments, [Comment]
      attribute :created_at, DateTime
      attribute :current_state, String # (accepted, delivered, finished, started, rejected, planned, unstarted, unscheduled)
      attribute :deadline, DateTime
      attribute :description, String
      attribute :estimate, Float
      attribute :external_id, String
      attribute :follower_ids, [Integer]
      attribute :followers, [Person]
      attribute :integration_id, Integer
      attribute :kind, String
      attribute :label_ids, [Integer]
      attribute :labels, [Label]
      attribute :name, String
      attribute :owned_by_id, Integer # deprecated!
      attribute :owned_by, Person
      attribute :owner_ids, [Integer]
      attribute :owners, [Person]
      attribute :planned_iteration_number, Integer
      attribute :project_id, Integer
      attribute :requested_by, Person
      attribute :requested_by_id, Integer
      attribute :story_type, String # (feature, bug, chore, release)
      attribute :task_ids, [Integer]
      attribute :tasks, [Task]
      attribute :updated_at, DateTime
      attribute :url, String


      class UpdateRepresenter < Representable::Decorator
        include Representable::JSON

        property :follower_ids, if: ->(_) { !follower_ids.blank? }
        property :name
        property :after_id
        property :before_id
        property :description
        property :story_type
        property :current_state
        property :estimate
        property :accepted_at
        property :deadline
        property :requested_by_id
        property :owner_ids, if: ->(_) { !owner_ids.blank? }
        collection :labels, class: Label, decorator: Label::UpdateRepresenter, render_empty: true
        property :integration_id
        property :external_id
      end

      # @return [String] Comma separated list of labels.
      def label_list
        @label_list ||= labels.collect(&:name).join(',')
      end

      # Adds a new label to the story.
      #
      # @param [Label|Hash|String] label
      def add_label(label)
        new_label = if label.kind_of?(String)
          Label.new(name: label)
        else
          label
        end

        # Use attribute writer to get coercion and dirty tracking.
        self.labels = (labels ? labels.dup : []).push(new_label)
      end

      # Assigns owner of story
      # @param [Person|Integer] owner
      def add_owner(person)
        person_id = if person.kind_of?(Person)
                     person.id
                   else
                     person
                   end

        Endpoints::StoryOwners.new(client).create(project_id, id, id: person_id)
      end

      # Provides a list of all the activity performed on the story.
      #
      # @param [Hash] params
      # @return [Array[Activity]]
      def activity(params = {})
        Endpoints::Activity.new(client).get_story(project_id, id, params)
      end

      # Provides a list of all the comments on the story.
      #
      # @param [Hash] params
      # @return [Array[Comment]]
      def comments(params = {})
        if params.blank? && @comments.present?
          @comments
        else
          @comments = Endpoints::Comments.new(client).get(project_id, id, params)
        end
      end

      # Provides a list of all the tasks on the story.
      #
      # @param [Hash] params
      # @return [Array[Task]]
      def tasks(params = {})
        if params.blank? && @tasks.present?
          @tasks
        else
          @tasks = Endpoints::Tasks.new(client).get(project_id, id, params)
        end
      end

      # Provides a list of all the owners of the story.
      #
      # @param [Hash] params
      # @return [Array[Person]]
      def owners(params = {})
        if params.blank? && @owners.present?
          @owners
        else
          @owners = Endpoints::StoryOwners.new(client).get(project_id, id, params)
        end
      end

      # @param [Hash] params attributes to create the task with
      # @return [Task] newly created Task
      def create_task(params)
        Endpoints::Task.new(client).create(project_id, id, params)
      end

      # @param [Hash] params attributes to create the comment with
      # @return [Comment] newly created Comment
      def create_comment(params)
        Endpoints::Comment.new(client).create(project_id, id, params)
      end

      # Save changes to an existing Story.
      def save
        raise ArgumentError, 'Can not update a story with an unknown project_id.' if project_id.nil?

        Endpoints::Story.new(client).update(self, UpdateRepresenter.new(Story.new(self.dirty_attributes)))
      end
    end
  end
end
