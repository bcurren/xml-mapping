require 'rexml/document'
require "xml/xpath"

module XML

  module Mapping

    def self.append_features(base)
      super
      base.extend(ClassMethods)
      base.xmlmapping_init
    end


    def fill_from_rexml(xml)
      pre_load(xml)
      self.class.text_nodes.each_pair do |attrname,path|
        self.send "#{attrname}=".intern, path.first(xml).text
      end
      self.class.int_nodes.each_pair do |attrname,(path,opts)|
        begin
          self.send "#{attrname}=".intern, path.first(xml).text.to_i
        rescue XML::XPathError
          raise unless opts[:optional]
        end
      end
      self.class.object_nodes.each_pair do |attrname,(klass,path)|
        self.send "#{attrname}=".intern, klass.load_from_rexml(path.first(xml))
      end
      self.class.boolean_nodes.each_pair do |attrname,(path,true_value,false_value)|
        self.send "#{attrname}=".intern, path.first(xml)==true_value
      end
      self.class.array_nodes.each_pair do |attrname,(klass,path)|
        arr = self.send "#{attrname}=".intern, []
        path.all(xml).each do |elt|
          arr << klass.load_from_rexml(elt)
        end
      end
      self.class.hash_nodes.each_pair do |attrname,(klass,path,key_path)|
        hash = self.send "#{attrname}=".intern, {}
        path.all(xml).each do |elt|
          key = key_path.first(elt).text
          value = klass.load_from_rexml(elt)
          hash[key] = value
        end
      end
      post_load
    end

    def pre_load(xml)
    end

    def post_load
    end


    def save_to_rexml
      xml = pre_save
      self.class.text_nodes.each_pair do |attrname,path|
        # TODO: XPath.write xml,path, self.send "#{attrname}".intern
      end
      post_save(xml)
      xml
    end

    def pre_save
      REXML::Document.new
    end

    def post_save(xml)
    end


    def save_to_file(filename)
      xml = save_to_rexml
      File.open(filename,"w") do |f|
        self.xml.write(f)
      end
    end


    module ClassMethods

      def add_accessor(name)
        name = name.id2name if name.kind_of? Symbol
        self.module_eval <<-EOS
        attr_accessor :#{name}
      EOS
      end

      def load_from_file(filename)
        xml = REXML::Document.new(File.new(filename))
        load_from_rexml(xml.root)
      end

      def load_from_rexml(xml)
        obj = self.new
        obj.fill_from_rexml(xml)
        obj
      end


      attr_accessor :text_nodes, :int_nodes,
        :object_nodes, :array_nodes, :hash_nodes, :boolean_nodes

      def xmlmapping_init
        @text_nodes = {}
        @int_nodes = {}
        @object_nodes = {}
        @array_nodes = {}
        @hash_nodes = {}
        @boolean_nodes = {}
      end


      def text_node(attrname,path)
        text_nodes[attrname] = XML::XPath.new(path)
        add_accessor attrname
      end

      def array_node(attrname,klass,path)
        array_nodes[attrname] = [klass,XML::XPath.new(path)]
        add_accessor attrname
      end

      def hash_node(attrname,klass,path,key_path)
        hash_nodes[attrname] = [klass,XML::XPath.new(path),XML::XPath.new(key_path)]
        add_accessor attrname
      end

      def object_node(attrname,klass,path)
        object_nodes[attrname] = [klass,XML::XPath.new(path)]
        add_accessor attrname
      end

      def int_node(attrname,path,opts={})
        int_nodes[attrname] = [XML::XPath.new(path),opts]
        add_accessor attrname
      end

      def boolean_node(attrname,path,true_value,false_value)
        boolean_nodes[attrname] = [XML::XPath.new(path),true_value,false_value]
        add_accessor attrname
      end

      def comma_separated_strings_node(*args)
        #TODO
      end

      def boolean_presence_node(*args)
        #TODO
      end
    end

  end

end
