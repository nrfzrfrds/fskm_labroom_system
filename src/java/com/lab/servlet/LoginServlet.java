package com.lab.servlet;

import com.lab.dao.LoginDAO;
import com.lab.dao.UserDAO;
import com.lab.model.User;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login");
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email != null) {
            email = email.trim();
        }
        if (password != null) {
            password = password.trim();
        }

        // Validate email is not empty
        if (email == null || email.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login&error=Email%20is%20required");
            return;
        }

        // Validate password is not empty
        if (password == null || password.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login&error=Password%20is%20required");
            return;
        }

        boolean valid = UserDAO.validateUser(email, password);

        if (valid) {
            HttpSession session = request.getSession();
            String userType = LoginDAO.login(email);
            
            // Fetch the full user details to get the User ID
            User loggedInUser = UserDAO.getUserByEmail(email);
            
            session.setAttribute("user", email);
            session.setAttribute("userType", userType);
            // Save the User ID so BookingServlet can find it
            session.setAttribute("userId", loggedInUser.getUserID());

            if ("staff".equalsIgnoreCase(userType) || "labstaff".equalsIgnoreCase(userType)) {
                response.sendRedirect(request.getContextPath() + "/staff/dashboard.jsp");
            } else {
                // Both Students and Lecturers will now go here!
                response.sendRedirect(request.getContextPath() + "/student/dashboard.jsp");
            }
        } else {
            // Invalid credentials — send back with error message
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login&error=Incorrect%20username%20or%20password.%20Please%20try%20again");
        }
    }
}