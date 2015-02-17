module RolesUi
  module UserExtensions
    class WrongAdminRolesArgument < StandardError; end

    def self.included(base)
      base.send :has_many, :assignments, :class_name => 'RolesUi::Assignment', :as => :localuser, :dependent => :destroy
      base.send :has_many, :roles, :through => :assignments, :source => :role, :class_name => 'RolesUi::Role'
      base.send :attr_accessible, :role_ids, :roles_attributes

      base.extend(ClassMethods)
    end

    module ClassMethods
      def with_role(role_name)
        includes(:roles).where(RolesUi::Role.table_name => { name: role_name.to_s})
      end
    end

    def admin?
      if RolesUi.admin_roles
        case RolesUi.admin_roles
        when Array
          RolesUi.admin_roles.each do |role|
            role = RolesUi::Role.find_by_name(role)
            has_role?(role) ? return true : return false
          end
        when Symbol
          role = RolesUi::Role.find_by_name(RolesUi.admin_roles)
            has_role?(role) ? return true : return false
        else
          return false
        end
      else
        super
      end
    end

    def add_role(role)
      role = RolesUi::Role.find_last_by_name(role.to_s) if role.is_a?(String) or role.is_a?(Symbol)
      self.roles << role unless self.has_role?(role)
    end

    def remove_role(role)
      role = RolesUi::Role.find_last_by_name(role.to_s) if role.is_a?(String) or role.is_a?(Symbol)
      self.roles.delete(role) if self.has_role?(role)
    end

    def has_role?(role)
      role = RolesUi::Role.find_last_by_name(role.to_s) if role.is_a?(String) or role.is_a?(Symbol)
      self.roles.include?(role)
    end

    def has_any_role?(*roles)
      if roles.empty?
        self.roles.any?
      else
        roles.map! { |role| role.to_s }
        self.roles.any? { |role| roles.include?(role.name) }
      end
    end

    # def method_missing(meth, *args, &block)
    #   roles_methods = RolesUi::Role.all.map{ |r| "#{r.name}?"}
    #   if roles_methods.include? meth.to_s
    #     has_role?
    #   else
    #     super
    #   end
    # end
  end
end
