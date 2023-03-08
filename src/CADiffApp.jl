module CADiffApp
using CSV
using SimpleWebsockets
using HTTP
using CurricularAnalytics
#using CurricularAnalyticsDiff
using JSON

greet() = print("Hello World!")

function julia_main()::Cint
    # HTTP.listen! and HTTP.serve! are the non-blocking versions of HTTP.listen/HTTP.serve
    server = HTTP.serve() do request::HTTP.Request
        @show request
        @show request.method
        @show HTTP.header(request, "Content-Type")
        #bod = HTTP.parse_multipart_form(request)
        # using bod[1].name is seemingly a no-go. until you figure it out, use hard-coded order: [1] is the method and [2] onwards is the content 
        # println(String(read(bod[1].data)))
        #@show request.body
        request_string = String(request.body)
        println(request_string)
        request_strings = split(request_string, "&")
        try
            response = ""
            clean_params = ""
            affected = ""
            html_resp = ""
            method = split(request_strings[1], "=")[2]
            # this is going to be chained if-elses, julia has no native switch, and I don't want to add another package
            if (method == "add-course")
                response = "Alright! Let's add a course!"
                # sanitize for add course
                clean_params = sanitize_add_course(request_strings[2:end])
                # then call it TODO
                affected = add_course_institutional(clean_params[1], big_curric, clean_params[2], clean_params[3], clean_params[4])
                (affected, count, html_resp) = print_affected_plans_web(affected)
                affected = affected * "Number of plans affected $count" #oop
            elseif (method == "add-prereq")
                response = "Alright! Let's add a prereq!"
                # sanitize for add-prereq
                clean_params = sanitize_add_prereq(request_strings[2:end])
                # then call it TODO
                affected = add_prereq_institutional(big_curric, clean_params[1], clean_params[2])
                (affected, count, html_resp) = print_affected_plans_web(affected)
                affected = affected * "Number of plans affected $count"
            elseif (method == "remove-course")
                response = "Alright! Let's remove a course!"
                # sanitize for remove prereq
                clean_params = sanitize_remove_course(request_strings[2:end])
                # then call it
                affected = delete_course_institutional(clean_params[1], big_curric)
                # collect the plans and print properly
                (affected, count, html_resp) = print_affected_plans_web(affected)
                affected = affected * "Number of plans affected $count"
            elseif (method == "remove-prereq")
                response = "Alright! Let's remove a prereq!"
                #sanitize for remove prereq
                clean_params = sanitize_remove_prereq(request_strings[2:end])
                # then call it
                affected = delete_prerequisite_institutional(clean_params[1], clean_params[2], big_curric)
                (affected, count, html_resp) = print_affected_plans_web(affected)
                affected = affected * "Number of plans affected $(count)"
            else
                throw(ArgumentError("Hey, I'm not sure what method you're trying to call. Please try again :)"))
            end
            # if all is well so far, respond with html
            resp = institutional_response_first_half * html_resp * institutional_response_second_half
            println(resp)
            #return HTTP.Response("$resp") #="$response, \n $clean_params \n $affected"=#
        catch e
            showerror(stdout, e)
            display(stacktrace(catch_backtrace()))
            #return HTTP.Response(400, "Error: $e")
        end
    end
    # HTTP.serve! returns an `HTTP.Server` object that we can close manually
    close(server)
    return 0
end

end # module
