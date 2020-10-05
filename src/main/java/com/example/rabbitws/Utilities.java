package com.example.rabbitws;

import java.io.*;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.Properties;

public class Utilities {

    public static Properties getPropertiesFromFile() {

        Properties prop = new Properties();
        InputStream is = null;

        try {
            String environment = System.getenv("environment");
            prop.load(Utilities.class.getClassLoader().getResourceAsStream(environment+".properties"));
        } catch(IOException e) {
            System.out.println(e.toString());
      }
        return prop;
    }


    public static String checkRabbitSocket (String hostname, int port) throws Exception {

	SocketAddress socketAddress = new InetSocketAddress(hostname, port);
        Socket socket = new Socket();
	int timeout = 2000;
        String line = "";
        StringBuffer lines = new StringBuffer();
        String output = "";
        try {
            socket.connect(socketAddress, timeout);
            InputStream input = socket.getInputStream();
            PrintWriter writer = new PrintWriter(socket.getOutputStream());
            writer.println("check\r\n\r\n\r\n\r\n");
            writer.println();
            writer.flush();

            byte[] buffer = new byte[1024];
            int read;
            while((read = input.read(buffer)) != -1) {
                output = new String(buffer, 0, read);
                System.out.println(output);
                System.out.flush();
            };
            socket.close();
        } catch (UnknownHostException ex) {

            System.out.println("Server not found: " + ex.getMessage());
            System.out.println("Failed connection to " + hostname + ":" + port);
            return "Failed connection to RabbitMQ";

        } catch (IOException ex) {
            if (ex.getMessage().equals("Connection reset") && output.contains("AMQP")) { //if RabbitMQ gives RST is running because readiness probe gives "Connection refused" if RabbitMQ is not running
                System.out.println("Successful connection to " + hostname + ":" + port);
                return "Successful connection to RabbitMQ";
            } else {
                System.out.println("I/O error: " + ex.getMessage());
                System.out.println("Failed connection to " + hostname + ":" + port);
                return "Failed connection to RabbitMQ";
            }
        }
        System.out.println("RabbitMQ not detected in " + hostname + ":" + port);
        System.out.println(lines.toString());
        return("Failed connection to RabbitMQ");
    }
}
