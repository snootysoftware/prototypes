xml.declare!(:DOCTYPE, :html)
xml.html do
  xml.head do
    xml << "\n  "
    xml.title do
      xml << "Foo"
    end
    xml << "\n  "
    xml << ""
    xml << stylesheet_link_tag("application", media: "all", "data-turbolinks-track" => true)
    xml << "\n  "
    xml << ""
    xml << javascript_include_tag("application", "data-turbolinks-track" => true)
    xml << "\n  "
    xml << ""
    xml << csrf_meta_tags
    xml << "\n"
  end
  xml << "\n"
  xml.body do
    xml << "\n\n"
    xml << ""
    xml << yield
    xml << "\n\n"
    xml.p("class" => "something") do
      xml << "foo"
    end
    xml << "\n\n"
    xml.img("src" => "a.png")
    xml << "\n\n"
    xml << ""
    @bars.each do |bar|
      xml << "\n  Hallo\n"
      xml << ""
    end
    xml << "\n\n"
    xml << ""
    if @foo
      xml << "\n  foo\n"
      xml << ""
    else
      xml << "\n  not foo\n"
      xml << ""
    end
    xml << "\n\n"
    xml << ""
    if @foo
      xml << "\n  foo\n"
      xml << ""
    else
      xml << "\n  not foo\n"
      xml << ""
    end
    xml << "\n\n\n\n"
  end
end