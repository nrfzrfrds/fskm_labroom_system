package com.lab.servlet;

import com.lab.dao.UserDAO;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet("/ProfilePictureServlet")
@MultipartConfig(maxFileSize = 10485760L, maxRequestSize = 12582912L, fileSizeThreshold = 0)
public class ProfilePictureServlet extends HttpServlet {

    private static final long MAX_UPLOAD_BYTES = 10L * 1024L * 1024L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        String user = session != null ? (String) session.getAttribute("user") : null;

        if (user == null || user.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/auth/index.jsp?mode=login&error=Please%20login%20first");
            return;
        }

        Part part;
        try {
            part = request.getPart("profilePicture");
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/user/my-account.jsp?error=Profile%20picture%20must%20be%2010MB%20or%20less");
            return;
        }

        if (part == null || part.getSize() <= 0) {
            response.sendRedirect(request.getContextPath() + "/user/my-account.jsp?error=Please%20choose%20an%20image%20to%20upload");
            return;
        }

        if (part.getSize() > MAX_UPLOAD_BYTES) {
            response.sendRedirect(request.getContextPath() + "/user/my-account.jsp?error=Profile%20picture%20must%20be%2010MB%20or%20less");
            return;
        }

        String contentType = part.getContentType();
        if (contentType == null || !contentType.toLowerCase().startsWith("image/")) {
            response.sendRedirect(request.getContextPath() + "/user/my-account.jsp?error=Only%20image%20files%20are%20allowed");
            return;
        }

        String fileName = buildFileName(user, part);
        String relativePath = "/uploads/profile-pictures/" + fileName;

        String uploadDir = getServletContext().getRealPath("/uploads/profile-pictures");
        if (uploadDir == null) {
            response.sendRedirect(request.getContextPath() + "/user/my-account.jsp?error=Upload%20folder%20is%20not%20available");
            return;
        }

        Path uploadPath = Paths.get(uploadDir);
        Files.createDirectories(uploadPath);

        Path targetFile = uploadPath.resolve(fileName);
        try (InputStream input = part.getInputStream()) {
            Files.copy(input, targetFile, StandardCopyOption.REPLACE_EXISTING);
        }

        if (UserDAO.updateProfilePicture(user, relativePath)) {
            response.sendRedirect(request.getContextPath() + "/user/my-account.jsp?message=Profile%20picture%20updated%20successfully");
        } else {
            response.sendRedirect(request.getContextPath() + "/user/my-account.jsp?error=Unable%20to%20save%20your%20profile%20picture");
        }
    }

    private String buildFileName(String email, Part part) {
        String ext = getExtension(part);
        String safeUser = email.replaceAll("[^A-Za-z0-9]", "_");
        return safeUser + "_" + UUID.randomUUID().toString().replace("-", "") + ext;
    }

    private String getExtension(Part part) {
        String submitted = getSubmittedFileName(part);
        if (submitted != null) {
            int dotIndex = submitted.lastIndexOf('.');
            if (dotIndex >= 0 && dotIndex < submitted.length() - 1) {
                return submitted.substring(dotIndex).toLowerCase();
            }
        }

        String contentType = part.getContentType();
        if (contentType == null) {
            return "";
        }

        if (contentType.equalsIgnoreCase("image/jpeg")) return ".jpg";
        if (contentType.equalsIgnoreCase("image/png")) return ".png";
        if (contentType.equalsIgnoreCase("image/gif")) return ".gif";
        if (contentType.equalsIgnoreCase("image/webp")) return ".webp";
        return "";
    }

    private String getSubmittedFileName(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) {
            return null;
        }

        for (String content : header.split(";")) {
            String trimmed = content.trim();
            if (trimmed.startsWith("filename")) {
                String fileName = trimmed.substring(trimmed.indexOf('=') + 1).trim().replace("\"", "");
                int lastSlash = Math.max(fileName.lastIndexOf('/'), fileName.lastIndexOf('\\'));
                return lastSlash >= 0 ? fileName.substring(lastSlash + 1) : fileName;
            }
        }

        return null;
    }
}
