package com.lab.servlet;

import com.lab.dao.UserDAO;
import com.lab.model.User;
import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class ManageUsersServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isLoggedIn(request)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login&error=Please%20login%20first");
            return;
        }

        String editId = request.getParameter("editId");
        if (editId != null && !editId.trim().isEmpty()) {
            try {
                User selectedUser = UserDAO.getUserById(Integer.parseInt(editId));
                request.setAttribute("selectedUser", selectedUser);
            } catch (NumberFormatException e) {
                request.setAttribute("errorMessage", "Invalid user selected.");
            }
        }

        List<User> users = UserDAO.getAllUsers();
        request.setAttribute("users", users);
        request.getRequestDispatcher("staff/manage-users.jsp").forward(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        if (!isLoggedIn(request)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login&error=Please%20login%20first");
            return;
        }

        String action = request.getParameter("action");

        if ("update".equals(action)) {
            updateUser(request, response);
            return;
        }

        if ("delete".equals(action)) {
            deleteUser(request, response);
            return;
        }

        response.sendRedirect("ManageUsersServlet?error=Unknown%20action");
    }

    private void updateUser(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            int userID = Integer.parseInt(request.getParameter("userID"));
            User existingUser = UserDAO.getUserById(userID);

            if (existingUser == null) {
                response.sendRedirect("ManageUsersServlet?error=User%20not%20found");
                return;
            }

            String newEmail = request.getParameter("email");
            if (!existingUser.getEmail().equalsIgnoreCase(newEmail) && UserDAO.emailExists(newEmail)) {
                response.sendRedirect("ManageUsersServlet?editId=" + userID + "&error=Email%20already%20exists");
                return;
            }

            String password = request.getParameter("password");
            if (password == null || password.trim().isEmpty()) {
                password = existingUser.getPassword();
            }

            User user = new User();
            user.setUserID(userID);
            user.setName(request.getParameter("name"));
            user.setInstitutionId(request.getParameter("institutionId"));
            user.setEmail(newEmail);
            user.setPhoneNum(request.getParameter("phoneNum"));
            user.setUserType(request.getParameter("userType"));
            user.setPassword(password);

            boolean updated = UserDAO.updateUser(user);

            if (updated) {
                HttpSession session = request.getSession(false);
                if (session != null && existingUser.getEmail().equalsIgnoreCase((String) session.getAttribute("user"))) {
                    session.setAttribute("user", newEmail);
                    session.setAttribute("userType", user.getUserType());
                }
                response.sendRedirect("ManageUsersServlet?message=User%20updated%20successfully");
            } else {
                response.sendRedirect("ManageUsersServlet?editId=" + userID + "&error=Unable%20to%20update%20user");
            }
        } catch (NumberFormatException e) {
            response.sendRedirect("ManageUsersServlet?error=Invalid%20user%20ID");
        }
    }

    private void deleteUser(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            int userID = Integer.parseInt(request.getParameter("userID"));
            User selectedUser = UserDAO.getUserById(userID);

            if (selectedUser == null) {
                response.sendRedirect("ManageUsersServlet?error=User%20not%20found");
                return;
            }

            HttpSession session = request.getSession(false);
            if (session != null && selectedUser.getEmail().equalsIgnoreCase((String) session.getAttribute("user"))) {
                response.sendRedirect("ManageUsersServlet?error=You%20cannot%20delete%20the%20current%20logged-in%20account");
                return;
            }

            boolean deleted = UserDAO.deleteUser(userID);

            if (deleted) {
                response.sendRedirect("ManageUsersServlet?message=User%20deleted%20successfully");
            } else {
                response.sendRedirect("ManageUsersServlet?error=Unable%20to%20delete%20user");
            }
        } catch (NumberFormatException e) {
            response.sendRedirect("ManageUsersServlet?error=Invalid%20user%20ID");
        }
    }

    private boolean isLoggedIn(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null && session.getAttribute("user") != null;
    }
}
