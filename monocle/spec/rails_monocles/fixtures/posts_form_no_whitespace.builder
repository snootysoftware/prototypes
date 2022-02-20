xml.h1("class" => "title") do
  xml << "New post"
end
xml.div("class" => "columns") do
  xml.div("class" => "column is-half") do
    xml << simple_form_for(@post || Post.new, defaults: { wrapper: false }) do |form|
      xml << form.input(:title, label: "Title")
      xml << form.input(:author, label: "Writer")
      xml.div("class" => "field") do
        xml.div("class" => "control") do
          xml << form.submit(class: "button is-link")
        end
      end
    end
  end
end
