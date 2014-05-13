module FormsHelper
  def link_to_add_fields(name, f, association)
    new_object = OpenStruct.new(@fb.fields)
    id = new_object.object_id
    fields = f.fields_for(association, new_object, index: id) do |builder|
      render(name, f: builder)
    end
    link_to(name, '#', class: "add_fields", data: {fields: fields.gsub("\n", "")})
  end

  def link_to_add_options(name, f, association)
    fields = f.fields_for(association, index: "") do |builder|  
      render(name, f: builder)  
    end  
    link_to('Add Options', '#', class: "add_options", data: {fields: fields.gsub("\n", "")})
  end
end
