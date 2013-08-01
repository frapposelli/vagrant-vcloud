module VagrantPlugins
  module VCloud
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          #puts "DUMPING MACHINE STUFF: " + env[:machine].inspect
          
          vmId = env[:machine].id
          if vmId
            env[:ui].info("VM has been created and ID is : [#{vmId}]")
            true
          else
            env[:ui].error("VM has not been created, ID is nil!")
            false
          end


          @app.call env
        end
      end
    end
  end
end
