module VagrantPlugins
  module VCloud
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          #puts "DUMPING MACHINE STUFF: " + env[:machine].inspect
          
          vAppId = env[:machine].get_vapp_id
          if vAppId.nil?
            env[:ui].warn("vApp has not been created")
            env[:result] = false
          else
            env[:ui].info("vApp has been created and ID is : [#{vAppId}]")
            
            vmId = env[:machine].id
            if vmId
              env[:ui].info("VM has been added to vApp and ID is : [#{vmId}]")
              env[:result] = true
           else
              env[:ui].warn("VM has not been added to vApp")
              env[:result] = false
           end



          
          end


          @app.call env
        end
      end
    end
  end
end
