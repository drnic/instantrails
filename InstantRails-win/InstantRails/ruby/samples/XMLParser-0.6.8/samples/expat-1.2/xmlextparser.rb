require 'xml/parser'

module XML
  class ExtParser < Parser

    def readResource(base, systemId, publicId = nil)
      systemId = base + systemId unless base.nil?
      open(systemId).read
    end

    def parse(*args)
      setParamEntityParsing(XML::Parser::PARAM_ENTITY_PARSING_UNLESS_STANDALONE)

      if iterator?
        super(*args) do |event, name, data|
          if (event ==  XML::Parser::EXTERNAL_ENTITY_REF)
            base, systemId, publicId = data
            extp = self.class.new(self, name)
            extp.parse(readResource(base, systemId)) do |event, name, data|
              yield(event, name, data)
            end
            extp.done
          else
            yield(event, name, data)
          end
        end
      else
        super(*args)
      end
    end

    def externalEntityRef(context, base, systemId, publicId)
##      p ["externalEntityRef", context, base, systemId, publicId]
      extp = self.class.new(self, context)
      extp.parse(readResource(base, systemId))
      extp.done
    end
  end
end
