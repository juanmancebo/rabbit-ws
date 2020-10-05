package com.example.rabbitws;

import java.util.Properties;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
public class Principal {

	@RequestMapping("/")


        public String index() {
                String output = "";
                Properties properties = Utilities.getPropertiesFromFile();
                if (properties==null || properties.getProperty("amqp.host")==null || properties.getProperty("amqp.port")==null)  {
              output = "Error. Was not able to read properties";
                    System.out.println(output);
                }
                else {

                    String hostname = properties.getProperty("amqp.host");
                    int port = Integer.parseInt(properties.getProperty("amqp.port"));
                    try {
                    	output = output+Utilities.checkRabbitSocket(hostname, port);
                        //System.out.println(output);
                    } catch (Exception e) {
			//e.printStackTrace();
                        System.out.println("Failed connection to " + hostname + ":" + port);
                        System.out.println("error: " + e.getMessage());
                        return "Failed connection to RabbitMQ";
		    } 

                }
                return output;
            }

}

