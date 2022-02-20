xml.h1("class" => "title") do
  xml << "Posts"
end

xml.table("class" => "table is-bordered is-striped is-narrow is-hoverable is-fullwidth") do
  xml.thead do
    xml.tr do
      xml.th do
        xml << "Title"
      end
      xml.th do
        xml << "Writer"
      end
      xml.th do
        xml << "Actions"
      end
    end
  end

  xml.tbody do
    @posts.each do |post|
      xml.tr do
        xml.td do
          xml << link_to(post.title, edit_post_path(post))
        end
        xml.td do
          xml << post.author
        end

        xml.td("class" => "has-text-centered") do
          xml << button_to("Delete", { action: "destroy", id: post.id }, method: :delete, data: { confirm: "Are you sure?" }, class: "button is-danger")
        end
      end
    end
  end
end

xml.table("class" => "table is-bordered is-striped is-narrow is-hoverable is-fullwidth") do
  xml.thead do
    xml.tr
  end
  xml.tbody do
    @posts.each do |post|
      xml.tr
    end
  end
end

xml.table("class" => "table is-bordered is-striped is-narrow is-hoverable is-fullwidth") do
  xml.thead do
    xml.tr do
      xml.th do
        xml << ""
      end
    end
  end
  xml.tbody do
    @posts.each do |post|
      xml.tr do
        xml.td do
          xml << link_to(post.XXX, edit_post_path(post))
        end
      end
    end
  end
end

xml.div("class" => "columns") do
  xml.div("class" => "column is-half") do
    xml << simple_form_for(@post || Post.new, defaults: { wrapper: false }) do |form|
      xml << form.input(:title, label: 'Title')
      xml << form.input(:author, label: 'Writer')
      xml << form.input(:published, wrapper: :boolean, label: 'Published')
      xml << form.input(:credits, as: :numeric, label: 'Credits')
      xml.div("class" => "field") do
        xml.div("class" => "control") do
          xml << form.submit(class: 'button is-link')
        end
      end
    end
  end
end

xml << link_to("New Post", new_post_path)
