package com.lab.servlet;

import com.lab.dao.UserDAO;
import com.lab.model.User;
import java.io.IOException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class RegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String name = request.getParameter("name");
        String institutionId = request.getParameter("institutionId");
        String email = request.getParameter("email");
        String phone = request.getParameter("phoneNum");
        String type = request.getParameter("userType");
        String password = request.getParameter("password");

        if (name != null) name = name.trim();
        if (institutionId != null) institutionId = institutionId.trim();
        if (email != null) email = email.trim();
        if (phone != null) phone = phone.trim();
        if (type != null) type = type.trim();
        if (password != null) password = password.trim();

        if (isBlank(name) || isBlank(institutionId) || isBlank(email) || isBlank(phone) || isBlank(type) || isBlank(password)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=register&error=Please%20fill%20in%20all%20required%20fields");
            return;
        }

        if (!isStrongPassword(password)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=register&error=Password%20must%20be%20at%20least%208%20characters%20and%20include%20at%20least%20one%20letter%2C%20one%20number%2C%20and%20one%20symbol");
            return;
        }

        if (!isValidInstitutionId(institutionId, type)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=register&error=Institution%20ID%20must%20start%20with%20S%20followed%20by%205%20digits%20for%20Student%2C%20L%20followed%20by%205%20digits%20for%20Lecturer%2C%20or%20ST%20followed%20by%203%20digits%20for%20Staff");
            return;
        }

        if (!isValidEmailDomain(email)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=register&error=Email%20must%20end%20with%20%40umt.edu.my.%20Please%20use%20your%20official%20UMT%20email");
            return;
        }

        if (!isValidPhone(phone)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=register&error=Phone%20number%20must%20not%20exceed%2011%20characters.%20Numbers%20only");
            return;
        }

        if (UserDAO.emailExists(email)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=register&error=Email%20already%20exists");
            return;
        }

        User user = new User();
        user.setName(name);
        user.setInstitutionId(institutionId);
        user.setEmail(email);
        user.setPhoneNum(phone);
        user.setUserType(type);
        user.setPassword(password);

        if (UserDAO.insertUser(user)) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login&message=Registration%20successful");
        } else {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=register&error=Unable%20to%20register%20user");
        }
    }

    private boolean isValidInstitutionId(String institutionId, String userType) {
        if (institutionId == null) return false;
        if ("student".equalsIgnoreCase(userType)) {
            return institutionId.matches("^[Ss]\\d{5}$");
        } else if ("lecturer".equalsIgnoreCase(userType)) {
            return institutionId.matches("^[Ll]\\d{5}$");
        } else if ("staff".equalsIgnoreCase(userType)) {
            return institutionId.matches("^[Ss][Tt]\\d{3}$");
        }
        return false;
    }

    private boolean isValidEmailDomain(String email) {
        return email != null
                && email.toLowerCase().endsWith("@umt.edu.my");
    }

    private boolean isValidPhone(String phone) {
        return phone == null || phone.length() <= 11;
    }

    private boolean isStrongPassword(String password) {
        return password != null
                && password.matches("^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$");
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
