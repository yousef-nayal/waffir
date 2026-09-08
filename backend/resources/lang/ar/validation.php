<?php

return [
    'accepted' => 'يجب قبول :attribute.',
    'after' => 'يجب أن يكون :attribute تاريخاً بعد :date.',
    'after_or_equal' => 'يجب أن يكون :attribute تاريخاً مساوياً أو بعد :date.',
    'array' => 'يجب أن يكون :attribute مصفوفة.',
    'before' => 'يجب أن يكون :attribute تاريخاً قبل :date.',
    'between' => [
        'numeric' => 'يجب أن تكون قيمة :attribute بين :min و :max.',
        'string' => 'يجب أن يكون طول :attribute بين :min و :max أحرف.',
    ],
    'boolean' => 'يجب أن تكون قيمة :attribute صحيحة أو خاطئة.',
    'confirmed' => 'تأكيد :attribute غير متطابق.',
    'date' => ':attribute ليس تاريخاً صحيحاً.',
    'email' => 'يجب إدخال :attribute بصيغة صحيحة.',
    'exists' => ':attribute المحدد غير موجود.',
    'in' => ':attribute المحدد غير صالح.',
    'integer' => 'يجب أن يكون :attribute رقماً صحيحاً.',
    'max' => [
        'numeric' => 'يجب ألا تتجاوز قيمة :attribute :max.',
        'string' => 'يجب ألا يتجاوز :attribute :max أحرف.',
        'array' => 'لا يمكن أن يحتوي :attribute على أكثر من :max عناصر.',
    ],
    'min' => [
        'numeric' => 'يجب ألا تقل قيمة :attribute عن :min.',
        'string' => 'يجب ألا يقل :attribute عن :min أحرف.',
        'array' => 'يجب أن يحتوي :attribute على الأقل :min عناصر.',
    ],
    'numeric' => 'يجب أن يكون :attribute رقماً.',
    'regex' => 'صيغة :attribute غير صحيحة.',
    'required' => ':attribute مطلوب.',
    'string' => 'يجب أن يكون :attribute نصاً.',
    'unique' => ':attribute مستخدم مسبقاً.',
    'url' => 'صيغة :attribute للرابط غير صحيحة.',
    'attributes' => [
        'name' => 'الاسم', 'email' => 'البريد الإلكتروني', 'password' => 'كلمة المرور',
        'password_confirmation' => 'تأكيد كلمة المرور', 'phone_number' => 'رقم الجوال',
        'location_id' => 'الموقع', 'brand_id' => 'العلامة التجارية',
        'unit_id' => 'الوحدة', 'product_id' => 'المنتج', 'store_id' => 'المتجر',
        'amount' => 'الكمية', 'price' => 'السعر', 'value' => 'التقييم',
        'type' => 'النوع', 'category' => 'التصنيف', 'description' => 'الوصف',
    ],
];
