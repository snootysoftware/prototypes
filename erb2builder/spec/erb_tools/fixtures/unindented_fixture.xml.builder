xml.h1 do
  xml << "Posts"
end
xml.table do
  xml << ""
  xml.thead do
    xml << ""
    xml.tr do
      xml.th do
        xml << "Title"
      end
      xml.th do
        xml << "Writer"
      end
    end
    xml << ""
  end
  xml << ""
  xml.tbody do
    xml << ""
    @posts.each do |post|
      xml << ""
      xml.tr do
        xml.td do
          xml << ""
          if post
            xml << link_to(post.title, post)
          else
            xml << link_to(post.title, post)
          end
          xml << ""
        end
        xml.td do
          xml << ""
          xml << post.author
          xml << ""
        end
      end
      xml << ""
    end
    xml << ""
  end
  xml << ""
end
